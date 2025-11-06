import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'about_us.dart';


void main() {
  runApp(const LanguageFlashcardsApp());
}
// APP 

class LanguageFlashcardsApp extends StatelessWidget {
  const LanguageFlashcardsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Language Flashcards',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.lightGreen,
          accentColor: Colors.pinkAccent,
        ).copyWith(secondary: Colors.pinkAccent),
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.lightBlue, 
          foregroundColor: Colors.white, 
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 6,
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: const SplashOrLogin(),
    );
  }
}

//  MODELS 

class VocabItem {
  String id;
  String word;
  String meaning;
  String lang; // 'English' or 'Japanese'
  bool learned;

  VocabItem({
    required this.id,
    required this.word,
    required this.meaning,
    required this.lang,
    this.learned = false,
  });

  factory VocabItem.fromJson(Map<String, dynamic> j) => VocabItem(
        id: j['id'],
        word: j['word'],
        meaning: j['meaning'],
        lang: j['lang'],
        learned: j['learned'] ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'word': word,
        'meaning': meaning,
        'lang': lang,
        'learned': learned,
      };
}

class LanguageProgress {
  final int total;
  final int learned;
  final double percent;

  LanguageProgress(this.total, this.learned)
    : percent = total > 0 ? learned / total : 0.0;
}

// STORAGE HELPERS 

class LocalStorage {
  static Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();
  // Users stored as map email -> password (insecure but fine for offline demo)
  static const _usersKey = 'users_map';
  // current logged in email
  static const _currentUserKey = 'current_user_email';

  // Vocab per user: key: vocab_<email>
  static String vocabKey(String email) => 'vocab_$email';

  // users
  static Future<Map<String, String>> loadUsers() async {
    final prefs = await _prefs();
    final s = prefs.getString(_usersKey);
    if (s == null) return {};
    final Map<String, dynamic> j = jsonDecode(s);
    return j.map((k, v) => MapEntry(k, v.toString()));
  }

  static Future<void> saveUsers(Map<String, String> users) async {
    final prefs = await _prefs();
    await prefs.setString(_usersKey, jsonEncode(users));
  }

  static Future<void> setCurrentUser(String email) async {
    final prefs = await _prefs();
    await prefs.setString(_currentUserKey, email);
  }

  static Future<String?> getCurrentUser() async {
    final prefs = await _prefs();
    return prefs.getString(_currentUserKey);
  }

  static Future<void> logout() async {
    final prefs = await _prefs();
    await prefs.remove(_currentUserKey);
  }

  //vocab 
  static Future<List<VocabItem>> loadVocab(String email) async {
    final prefs = await _prefs();
    final s = prefs.getString(vocabKey(email));
    if (s == null) return [];
    final List<dynamic> arr = jsonDecode(s);
    return arr.map((e) => VocabItem.fromJson(e)).toList();
  }
  static Future<void> saveVocab(String email, List<VocabItem> list) async {
    final prefs = await _prefs();
    final j = list.map((e) => e.toJson()).toList();
    await prefs.setString(vocabKey(email), jsonEncode(j));
  }
}

// SPLASH / LOGIN ROUTE 

class SplashOrLogin extends StatefulWidget {
  const SplashOrLogin({super.key});

  @override
  State<SplashOrLogin> createState() => _SplashOrLoginState();
}

class _SplashOrLoginState extends State<SplashOrLogin> {
  String? _email;

  @override
  void initState() {
    super.initState();
    _checkLogged();
  }

  Future<void> _checkLogged() async {
    final e = await LocalStorage.getCurrentUser();
    // small delay for nicer transition
    await Future.delayed(const Duration(milliseconds: 400));
    if (e != null) {
      setState(() => _email = e);
      _goHome(e);
    } else {
      // go to Login
      if (mounted) {
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AuthScreen()));
      }
    }
  }

  void _goHome(String email) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => HomeScreen(email: email)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.flash_on_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 80,
            ),
            const SizedBox(height: 12),
            Text(
              'Language Flashcards',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 6),
            const Text('Offline demo', style: TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}

// AUTH SCREEN 

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    _formKey.currentState!.save();
    final users = await LocalStorage.loadUsers();

    await Future.delayed(const Duration(milliseconds: 450)); 

    if (_isLogin) {
      // login
      if (users.containsKey(_email) && users[_email] == _password) {
        await LocalStorage.setCurrentUser(_email);
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => HomeScreen(email: _email)),
          );
        }
      } else {
        setState(() {
          _error = 'Email hoặc mật khẩu không đúng.';
          _loading = false;
        });
      }
    } else {
      // register
      if (users.containsKey(_email)) {
        setState(() {
          _error = 'Email đã được sử dụng.';
          _loading = false;
        });
      } else {
        users[_email] = _password;
        await LocalStorage.saveUsers(users);
        await LocalStorage.setCurrentUser(_email);
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => HomeScreen(email: _email)),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isLogin ? 'Ðăng nhập' : 'Ðăng ký',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Offline account (demo)',
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 18),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          initialValue: '',
                          decoration: const InputDecoration(labelText: 'Email'),
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) =>
                              (v == null || v.isEmpty || !v.contains('@'))
                              ? 'Email không hợp lệ'
                              : null,
                          onSaved: (v) => _email = v!.trim(),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          initialValue: '',
                          decoration: const InputDecoration(
                            labelText: 'Mật khẩu',
                          ),
                          obscureText: true,
                          validator: (v) => (v == null || v.length < 4)
                              ? 'Mật khẩu ít nhất 4 kí tự'
                              : null,
                          onSaved: (v) => _password = v!.trim(),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _submit,
                            child: _loading
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    _isLogin ? 'Ðăng nhập' : 'Tạo tài khoản',
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _loading
                        ? null
                        : () {
                            setState(() {
                              _isLogin = !_isLogin;
                              _error = null;
                            });
                          },
                    child: Text(
                      _isLogin
                          ? 'Chưa có tài khoản? Ðăng ký'
                          : 'Ðã có tài khoản? Ðăng nhập',
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: () {
                      // quick demo account
                      setState(() {
                        _isLogin = true;
                        _email = 'demo@example.com';
                      });
                      _ensureDemoUserAndLogin();
                    },
                    child: const Text('Dùng tài khoản demo'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _ensureDemoUserAndLogin() async {
    final users = await LocalStorage.loadUsers();
    if (!users.containsKey('demo@example.com')) {
      users['demo@example.com'] = 'demo';
      await LocalStorage.saveUsers(users);
      // add demo vocab
      final demoList = [
        VocabItem(
          id: 'd1',
          word: 'Hello',
          meaning: 'Xin chào',
          lang: 'English',
        ),
        VocabItem(
          id: 'd2',
          word: 'Thank you',
          meaning: 'Cảm ơn',
          lang: 'English',
        ),
        VocabItem(
          id: 'd3',
          word: 'こんにちは',
          meaning: 'Xin chào',
          lang: 'Japanese',
        ),
        VocabItem(
          id: 'd4',
          word: 'またあした',
          meaning: 'Hẹn gặp lại ngày mai',
          lang: 'Japanese',
        ),
      ];
      await LocalStorage.saveVocab('demo@example.com', demoList);
    }
    await LocalStorage.setCurrentUser('demo@example.com');
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => HomeScreen(email: 'demo@example.com'),
        ),
      );
    }
  }
}

// HOME SCREEN 

class HomeScreen extends StatefulWidget {
  final String email;
  const HomeScreen({required this.email, super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<VocabItem> _vocab = [];
  bool _loading = true;
  String _selectedLang = 'English';

  @override
  void initState() {
    super.initState();
    _loadVocab();
  }

  Future<void> _loadVocab() async {
    setState(() => _loading = true);
    final list = await LocalStorage.loadVocab(widget.email);
    await Future.delayed(const Duration(milliseconds: 200));
    setState(() {
      _vocab = list;
      _loading = false;
    });
  }

  //Hàm tính tiến độ riêng
  Map<String, LanguageProgress> _getProgress() {
    final englishVocab = _vocab.where((e) => e.lang == 'English');
    final japaneseVocab = _vocab.where((e) => e.lang == 'Japanese');

    final progress = {
      'English': LanguageProgress(
        englishVocab.length,
        englishVocab.where((e) => e.learned).length,
      ),
      'Japanese': LanguageProgress(
        japaneseVocab.length,
        japaneseVocab.where((e) => e.learned).length,
      ),
    };
    return progress;
  }

  List<VocabItem> _filteredVocab() {
    return _vocab.where((e) => e.lang == _selectedLang).toList();
  }

  Future<void> _logout() async {
    await LocalStorage.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
        (r) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final progressMap = _getProgress();
    final currentVocab = _filteredVocab();
    final currentEmail = widget.email;

    return Scaffold(
      backgroundColor: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withOpacity(0.2),
      appBar: AppBar(
        title: const Text('Language Flashcards'),
        actions: [
          IconButton(
            tooltip: 'Đăng xuất',
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadVocab,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                color: Colors.white,
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        child: Text(
                          widget.email[0].toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Xin chào, ${widget.email.split('@').first}!',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            Text(
                              'Tổng từ vựng: ${_vocab.length} mục',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18, 
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Tiến độ học tập (theo ngôn ngữ)',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              //Hiển thị 2 Progress Card riêng biệt
              _buildProgressCard(
                'English',
                progressMap['English']!,
                Colors.lightBlue,
              ),
              const SizedBox(height: 12),
              _buildProgressCard(
                'Japanese',
                progressMap['Japanese']!,
                Colors.pinkAccent,
              ),

              const SizedBox(height: 20),
              // KHUNG CHỌN NGÔN NGỮ
              Text(
                'Ngôn ngữ làm việc hiện tại',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: ['English', 'Japanese']
                    .map(
                      (lang) => Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(lang),
                          selected: _selectedLang == lang,
                          selectedColor: Theme.of(
                            context,
                          ).colorScheme.secondaryContainer,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedLang = lang;
                              });
                            }
                          },
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 18),
              Text(
                'Chức năng (${_selectedLang})',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _featureCard(Icons.auto_stories, 'Học (Flashcards)', () {
                    if (currentVocab.isEmpty) {
                      _showSnack(
                        'Chưa có từ ${_selectedLang}. Vui lòng thêm từ trước.',
                      );
                      return;
                    }
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => FlashcardScreen(
                          vocab: currentVocab,
                          onUpdate: _onVocabUpdated,
                        ),
                      ),
                    );
                  }, Colors.lightBlue),
                  _featureCard(Icons.quiz, 'Làm quiz', () {
                    if (currentVocab.length < 2) {
                      _showSnack(
                        'Cần ít nhất 2 từ ${_selectedLang} để làm quiz.',
                      );
                      return;
                    }
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => QuizScreen(vocab: currentVocab),
                      ),
                    );
                  }, Colors.pinkAccent),
                  _featureCard(Icons.list_alt, 'Quản lý từ', () {
                    Navigator.of(context)
                        .push(
                          MaterialPageRoute(
                            builder: (_) => ManageVocabScreen(
                              email: currentEmail,
                              initialLang: _selectedLang,
                            ),
                          ),
                        )
                        .then((_) => _loadVocab());
                  }, Colors.green),
                  _featureCard(Icons.add_task, 'Thêm từ mới', () {
                    Navigator.of(context)
                        .push(
                          MaterialPageRoute(
                            builder: (_) => AddEditVocabScreen(
                              email: widget.email,
                              initialLang: _selectedLang,
                            ),
                          ),
                        )
                        .then((_) => _loadVocab());
                  }, Colors.orange),
                  _featureCard(Icons.info_outline, 'Giới thiệu', () {
                    Navigator.of(
                      context,
                    ).push(MaterialPageRoute(builder: (_) => const AboutUs()));
                  }, Colors.grey),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                'Danh sách từ ${_selectedLang} (sẵn)',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else if (currentVocab.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'Bạn chưa có từ ${_selectedLang} nào. Nhấn "Thêm từ mới" để bắt đầu.',
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: min(5, currentVocab.length), // Giới hạn 5 mục
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, idx) {
                    final item = currentVocab[idx];
                    return Dismissible(
                      key: Key(item.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        padding: const EdgeInsets.only(right: 20),
                        alignment: Alignment.centerRight,
                        decoration: BoxDecoration(
                          color: Colors.red.shade400,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) async {
                        // Xóa từ danh sách gốc
                        final originalIdx = _vocab.indexWhere(
                          (e) => e.id == item.id,
                        );
                        if (originalIdx >= 0) {
                          _vocab.removeAt(originalIdx);
                          await LocalStorage.saveVocab(widget.email, _vocab);
                          setState(() {});
                          _showSnack('Đã xóa từ');
                        }
                      },
                      child: ListTile(
                        tileColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        leading: CircleAvatar(
                          child: Text(item.lang[0]),
                          backgroundColor: item.lang == 'English'
                              ? Colors.lightBlue
                              : Colors.pinkAccent,
                        ),
                        title: Text(
                          item.word,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(item.meaning),
                        trailing: IconButton(
                          tooltip: 'Sửa',
                          icon: const Icon(Icons.edit),
                          onPressed: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AddEditVocabScreen(
                                  email: widget.email,
                                  editing: item,
                                ),
                              ),
                            );
                            _loadVocab();
                          },
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context)
              .push(
                MaterialPageRoute(
                  builder: (_) => AddEditVocabScreen(
                    email: widget.email,
                    initialLang: _selectedLang,
                  ),
                ),
              )
              .then((_) => _loadVocab());
        },
        icon: const Icon(Icons.add),
        label: Text('Thêm từ ${_selectedLang}'),
      ),
    );
  }

  //Widget Progress Card riêng cho từng ngôn ngữ
  Widget _buildProgressCard(
    String lang,
    LanguageProgress progress,
    Color langColor,
  ) {
    return Card(
      elevation: 4,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        // ignore: deprecated_member_use
        side: BorderSide(color: langColor.withOpacity(0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tiến độ ${lang}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: langColor.shade700,
              ),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(
                value: progress.percent,
                minHeight: 10,
                // ignore: deprecated_member_use
                backgroundColor: langColor.withOpacity(0.15),
                color: langColor,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Đã học: ${progress.learned} / ${progress.total} từ',
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
                Text(
                  '${(progress.percent * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: langColor.shade700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  //Widget Feature Card
  Widget _featureCard(
    IconData icon,
    String title,
    VoidCallback onTap,
    Color iconColor,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          // ignore: deprecated_member_use
          border: Border.all(color: iconColor.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              // ignore: deprecated_member_use
              color: iconColor.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              // ignore: deprecated_member_use
              backgroundColor: iconColor.withOpacity(0.15),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  void _showSnack(String s) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));

  Future<void> _onVocabUpdated() async {
    await _loadVocab();
  }
}

extension on Color {
  Color? get shade700 => null;
}


// MANAGE VOCAB SCREEN 

class ManageVocabScreen extends StatefulWidget {
  final String email;
  final String initialLang;
  const ManageVocabScreen({
    required this.email,
    this.initialLang = 'English',
    super.key,
  });

  @override
  State<ManageVocabScreen> createState() => _ManageVocabScreenState();
}

class _ManageVocabScreenState extends State<ManageVocabScreen> {
  List<VocabItem> _list = [];
  bool _loading = true;
  String _selectedLang = 'English';

  @override
  void initState() {
    super.initState();
    _selectedLang = widget.initialLang;
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final l = await LocalStorage.loadVocab(widget.email);
    await Future.delayed(const Duration(milliseconds: 150));
    setState(() {
      _list = l;
      _loading = false;
    });
  }

  Future<void> _save() async {
    await LocalStorage.saveVocab(widget.email, _list);
  }

  List<VocabItem> _filteredList() {
    return _list.where((e) => e.lang == _selectedLang).toList();
  }

  Future<void> _deleteItem(VocabItem item) async {
    final idx = _list.indexWhere((e) => e.id == item.id);
    if (idx >= 0) {
      setState(() {
        _list.removeAt(idx);
      });
      await _save();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã xóa từ')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentList = _filteredList();
    return Scaffold(
      backgroundColor: Theme.of(
        context,
        // ignore: deprecated_member_use
      ).colorScheme.surfaceContainerHighest.withOpacity(0.2),
      appBar: AppBar(title: const Text('Quản lý từ vựng')),
      body: Column(
        children: [
          // KHUNG CHỌN NGÔN NGỮ
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: ['English', 'Japanese']
                  .map(
                    (lang) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ChoiceChip(
                        label: Text(lang),
                        selected: _selectedLang == lang,
                        selectedColor: Theme.of(
                          context,
                        ).colorScheme.secondaryContainer,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedLang = lang;
                            });
                          }
                        },
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),

          // KẾT THÚC KHUNG
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : currentList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Chưa có từ ${_selectedLang} nào.'),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => _addNew(),
                          child: const Text('Thêm từ mới'),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: currentList.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final it = currentList[i];
                      return Dismissible(
                        key: Key(it.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          padding: const EdgeInsets.only(right: 20),
                          alignment: Alignment.centerRight,
                          decoration: BoxDecoration(
                            color: Colors.red.shade400,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) => _deleteItem(it),
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: it.lang == 'English'
                                  ? Colors.lightBlue.shade300
                                  : Colors.pinkAccent.shade200,
                              foregroundColor: Colors.white,
                              child: Text(it.lang[0]),
                            ),
                            title: Text(
                              it.word,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(it.meaning),
                            trailing: Wrap(
                              spacing: 8,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _editItem(it),
                                ),
                                IconButton(
                                  icon: Icon(
                                    it.learned
                                        ? Icons.check_circle_rounded
                                        : Icons.check_circle_outline,
                                    color: it.learned ? Colors.green : null,
                                  ),
                                  onPressed: () {
                                    final originalIdx = _list.indexWhere(
                                      (e) => e.id == it.id,
                                    );
                                    if (originalIdx >= 0) {
                                      setState(() {
                                        _list[originalIdx].learned =
                                            !_list[originalIdx].learned;
                                      });
                                      _save();
                                    }
                                  },
                                ),
                                // Nút xóa
                                IconButton(
                                  tooltip: 'Xóa từ',
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _deleteItem(it),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNew,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _addNew() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => AddEditVocabScreen(
              email: widget.email,
              initialLang: _selectedLang,
            ),
          ),
        )
        .then((_) => _load());
  }

  void _editItem(VocabItem it) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) =>
                AddEditVocabScreen(email: widget.email, editing: it),
          ),
        )
        .then((_) => _load());
  }
}

// =================== ADD / EDIT VOCAB SCREEN ===================

class AddEditVocabScreen extends StatefulWidget {
  final String email;
  final VocabItem? editing;
  final String initialLang;
  const AddEditVocabScreen({
    required this.email,
    this.editing,
    this.initialLang = 'English',
    super.key,
  });

  @override
  State<AddEditVocabScreen> createState() => _AddEditVocabScreenState();
}

class _AddEditVocabScreenState extends State<AddEditVocabScreen> {
  final _formKey = GlobalKey<FormState>();
  String _word = '';
  String _meaning = '';
  String _lang = 'English';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.editing != null) {
      _word = widget.editing!.word;
      _meaning = widget.editing!.meaning;
      _lang = widget.editing!.lang;
    } else {
      _lang = widget.initialLang;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() => _saving = true);
    final list = await LocalStorage.loadVocab(widget.email);
    if (widget.editing == null) {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final item = VocabItem(
        id: id,
        word: _word,
        meaning: _meaning,
        lang: _lang,
      );
      list.add(item);
    } else {
      final idx = list.indexWhere((e) => e.id == widget.editing!.id);
      if (idx >= 0) {
        list[idx].word = _word;
        list[idx].meaning = _meaning;
        list[idx].lang = _lang;
      }
    }
    await LocalStorage.saveVocab(widget.email, list);
    setState(() => _saving = false);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.editing != null;
    return Scaffold(
      backgroundColor: Theme.of(
        context,
        // ignore: deprecated_member_use
      ).colorScheme.surfaceContainerHighest.withOpacity(0.2),
      appBar: AppBar(title: Text(isEdit ? 'Sửa từ' : 'Thêm từ mới')),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    initialValue: _word,
                    decoration: const InputDecoration(labelText: 'Từ (word)'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Nhập từ' : null,
                    onSaved: (v) => _word = v!.trim(),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: _meaning,
                    decoration: const InputDecoration(
                      labelText: 'Nghĩa (meaning)',
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Nhập nghĩa' : null,
                    onSaved: (v) => _meaning = v!.trim(),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _lang,
                    items: const [
                      DropdownMenuItem(
                        value: 'English',
                        child: Text('English'),
                      ),
                      DropdownMenuItem(
                        value: 'Japanese',
                        child: Text('Japanese'),
                      ),
                    ],
                    onChanged: (v) => setState(() => _lang = v!),
                    decoration: const InputDecoration(labelText: 'Ngôn ngữ'),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const CircularProgressIndicator()
                          : Text(isEdit ? 'Lưu thay đổi' : 'Thêm từ'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// FLASHCARD SCREEN

class FlashcardScreen extends StatefulWidget {
  final List<VocabItem> vocab;
  final VoidCallback? onUpdate;
  const FlashcardScreen({required this.vocab, this.onUpdate, super.key});

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  late PageController _pageController;
  late List<VocabItem> _cards;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _cards = List<VocabItem>.from(widget.vocab);
    _pageController = PageController();
  }

  void _markLearned() async {
    final current = _cards[_index];
    setState(() => current.learned = true);
    // persist - note: we don't have email here, so we'll save by matching ID across local storage.
    final email = await LocalStorage.getCurrentUser();
    if (email != null) {
      final list = await LocalStorage.loadVocab(email);
      final idx = list.indexWhere((e) => e.id == current.id);
      if (idx >= 0) list[idx].learned = true;
      await LocalStorage.saveVocab(email, list);
    }
    widget.onUpdate?.call();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã đánh dấu "Đã nhớ"')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flashcards')),
      body: _cards.isEmpty
          ? const Center(child: Text('Không có thẻ nào'))
          : Column(
            children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _cards.length,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (context, i) {
                      final it = _cards[i];
                      return Padding(
                        padding: const EdgeInsets.all(18),
                        child: Center(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 12,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(22),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Align(
                                    alignment: Alignment.topRight,
                                    child: Chip(label: Text(it.lang)),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    it.word,
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    it.meaning,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 28),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: _markLearned,
                                        icon: const Icon(Icons.check),
                                        label: const Text('Đã nhớ'),
                                        style: ElevatedButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      OutlinedButton.icon(
                                        onPressed: () {
                                          // show details or flip? for simplicity show a dialog
                                          showDialog(
                                            context: context,
                                            builder: (_) => AlertDialog(
                                              title: Text(it.word),
                                              content: Text(
                                                'Nghĩa: ${it.meaning}\nNgôn ngữ: ${it.lang}',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                  child: const Text('Đóng'),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.info_outline),
                                        label: const Text('Chi tiết'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${_index + 1} / ${_cards.length}'),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              final prev = max(0, _index - 1);
                              _pageController.animateToPage(
                                prev,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            icon: const Icon(Icons.chevron_left),
                          ),
                          IconButton(
                            onPressed: () {
                              final next = min(_cards.length - 1, _index + 1);
                              _pageController.animateToPage(
                                next,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            icon: const Icon(Icons.chevron_right),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

// QUIZ SCREEN 

class QuizScreen extends StatefulWidget {
  final List<VocabItem> vocab;
  const QuizScreen({required this.vocab, super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late List<VocabItem> pool;
  int _qIndex = 0;
  int _score = 0;
  List<String> _options = [];
  String? _correctAnswer;

  @override
  void initState() {
    super.initState();
    pool = List<VocabItem>.from(widget.vocab);
    pool.shuffle();
    _prepareQuestion();
  }

  void _prepareQuestion() {
    if (_qIndex >= pool.length) return;
    final current = pool[_qIndex];
    _correctAnswer = current.meaning;
    final others = widget.vocab.where((e) => e.id != current.id).map((e) => e.meaning).toList();
    others.shuffle();
    final opts = <String>[];
    opts.add(_correctAnswer!);
    for (int i = 0; i < 3 && i < others.length; i++) {
      opts.add(others[i]);
    }
    opts.shuffle();
    setState(() => _options = opts);
  }

  void _select(String choice) {
    final correct = choice == _correctAnswer;
    if (correct) _score++;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(correct ? 'Ðúng!' : 'Sai'),
        content: Text('${correct ? "Chính xác" : "Ðáp án đúng: $_correctAnswer"}'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _next();
            },
            child: const Text('Ti?p'),
          )
        ],
      ),
    );
  }

  void _next() {
    if (_qIndex < pool.length - 1) {
      setState(() {
        _qIndex++;
        _prepareQuestion();
      });
    } else {
      // finish
      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Kết thúc Quiz'),
          content: Text('Ðiểm: $_score / ${pool.length}'),
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('Xong')),
            TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    pool.shuffle();
                    _qIndex = 0;
                    _score = 0;
                    _prepareQuestion();
                  });
                },
                child: const Text('Ôn lại')),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (pool.isEmpty) {
      return Scaffold(appBar: AppBar(title: const Text('Quiz')), body: const Center(child: Text('Không có câu hỏi')));
    }
    final cur = pool[_qIndex];
    return Scaffold(
      appBar: AppBar(title: const Text('Quiz')),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Câu ${_qIndex + 1} / ${pool.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('Ðiểm: $_score'),
                ]),
                const SizedBox(height: 12),
                Text(cur.word, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Chip(label: Text(cur.lang)),
              ]),
            ),
          ),
          const SizedBox(height: 18),
          ..._options.map((opt) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _select(opt),
                child: Text(opt),
              ),
            );
          }).toList(),
          const Spacer(),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Thoát'),
          )
        ]),
      ),
    );
  }
}

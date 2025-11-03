import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
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
      backgroundColor: const Color(0xFFeef6ff),
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: const [
          Icon(Icons.flash_on_rounded, color: Colors.blueAccent, size: 80),
          SizedBox(height: 12),
          Text('Language Flashcards',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          SizedBox(height: 6),
          Text('Offline demo', style: TextStyle(color: Colors.black54)),
        ]),
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

    await Future.delayed(const Duration(milliseconds: 450)); // small delay

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
      backgroundColor: const Color(0xFFf7fbff),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(_isLogin ? 'Ðăng nhập' : 'Ðăng ký',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Offline account (demo)', style: TextStyle(color: Colors.black54)),
                const SizedBox(height: 18),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(_error!, style: const TextStyle(color: Colors.red)),
                  ),
                Form(
                  key: _formKey,
                  child: Column(children: [
                    TextFormField(
                      initialValue: '',
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) =>
                          (v == null || v.isEmpty || !v.contains('@')) ? 'Email không hợp lệ' : null,
                      onSaved: (v) => _email = v!.trim(),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: '',
                      decoration: const InputDecoration(labelText: 'Mật khẩu'),
                      obscureText: true,
                      validator: (v) =>
                          (v == null || v.length < 4) ? 'Mật khẩu ít nhất 4 kí tự' : null,
                      onSaved: (v) => _password = v!.trim(),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _loading ? null : _submit,
                        child: _loading
                            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text(_isLogin ? 'Ðăng nhập' : 'Tạo tài khoản'),
                      ),
                    ),
                  ]),
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
                  child: Text(_isLogin ? 'Chưa có tài khoản? Ðăng ký' : 'Ðã có tài khoản? Ðăng nhập'),
                ),
                const SizedBox(height: 6),
                TextButton(
                  onPressed: () {
                    // quick demo account
                    setState(() {
                      _isLogin = true;
                      _email = 'demo@example.com';
                    });
                    // we prepopulate demo user if not exist
                    _ensureDemoUserAndLogin();
                  },
                  child: const Text('Dùng tài khoản demo'),
                )
              ]),
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
      // add some demo vocab for this user
      final demoList = [
        VocabItem(id: 'd1', word: 'Hello', meaning: 'Xin chào', lang: 'English'),
        VocabItem(id: 'd2', word: 'Thank you', meaning: 'Cảm ơn', lang: 'English'),
        VocabItem(id: 'd3', word: 'こんにちは', meaning: 'Xin chào', lang: 'Japanese'),
        VocabItem(id: 'd4', word: 'またあした', meaning: 'Hẹn gặp lại ngày mai', lang: 'Japanese'),
      ];
      await LocalStorage.saveVocab('demo@example.com', demoList);
    }
    await LocalStorage.setCurrentUser('demo@example.com');
    if (mounted) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => HomeScreen(email: 'demo@example.com')));
    }
  }
}

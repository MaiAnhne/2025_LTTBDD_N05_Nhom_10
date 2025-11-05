import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AboutUs extends StatelessWidget {
  const AboutUs({super.key});

  static const Color accentColor = Color(0xFF007BFF);
  static const Color neonAccent = Color(0xFF00BFFF);
  static const Color lightBackground = Color(0xFFf5f7fb);

  // Widget tiêu đề phụ
  static Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 30.0, bottom: 10.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: accentColor,
          ),
        ),
      ),
    );
  }

  Widget _contentBlock({
    required Widget imageWidget,
    required String title,
    required String content,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Image/Illustration
        Padding(padding: const EdgeInsets.only(right: 20), child: imageWidget),
        // Title and Text
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle(title),
              Text(
                content,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.justify,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Widget hiển thị từng thành viên
  static Widget _memberCard(String name, String msv) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: neonAccent, width: 1.5),
      ),
      elevation: 4,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color.fromARGB(
            255,
            244,
            156,
            218,
          ), // Background màu neon
          child: Text(
            name[0],
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          'MSV: $msv',
          style: const TextStyle(color: Color.fromARGB(255, 240, 130, 220)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const String missionContent =
        'Ứng dụng "Language Flashcards" cho phép người dùng lưu trữ, ôn tập và kiểm tra từ vựng một cách nhanh chóng. '
        'Các tính năng chính gồm:\n'
        '• Học từ bằng flashcards\n'
        '• Làm quiz kiểm tra kiến thức\n'
        '• Quản lý, thêm, sửa, xóa từ vựng\n'
        '• Ghi nhớ tiến độ học và lưu trữ dữ liệu cục bộ.';

    const String foundingStoryContent =
        'Trong thời đại hội nhập, khả năng sử dụng ngoại ngữ '
        'là kỹ năng vô cùng quan trọng. Tuy nhiên, việc ghi nhớ từ vựng theo cách truyền thống '
        'dễ gây nhàm chán và nhanh quên. Vì vậy, nhóm chúng em mong muốn tạo ra một ứng dụng '
        'giúp người học ghi nhớ từ vựng dễ dàng, sinh động và hiệu quả hơn. '
        'Đây là phiên bản "Language Flashcards" – ứng dụng học từ vựng ngoại ngữ tiện lợi và trực quan.';

    // Widget giả lập hình ảnh
    final Widget missionImageWidget = Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: neonAccent.withOpacity(0.2), // Nền nhạt
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color.fromARGB(255, 101, 248, 226),
          width: 2,
        ), // Viền neon
      ),
      child: const Icon(Icons.psychology_outlined, size: 50, color: neonAccent),
    );

    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        title: Text(
          'Về chúng tôi',
          style: GoogleFonts.vollkorn(
            color: const Color.fromARGB(255, 247, 243, 243),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: const Color.fromARGB(
          255,
          143,
          230,
          244,
        ), // Màu AppBar mạnh mẽ
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // MISSION SECTION (Phần Mục tiêu)
            _contentBlock(
              imageWidget: missionImageWidget,
              title: 'Mission (Mục tiêu)',
              content: missionContent,
            ),

            const SizedBox(height: 30),

            // FOUNDING STORY SECTION (Phần Lý do thực hiện)
            _sectionTitle('Founding Story (Lý do thực hiện)'),
            Text(
              foundingStoryContent,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Colors.black87,
              ),
              textAlign: TextAlign.justify,
            ),

            const SizedBox(height: 40),
            const Divider(
              thickness: 1.2,
              color: Color.fromARGB(255, 116, 226, 173),
            ),
            const SizedBox(height: 12),

            // Phần kết Giới thiệu thành viên
            _sectionTitle('Nhóm phát triển'),
            _memberCard('Nguyễn Mai Anh', '23010490'),
            _memberCard('Nguyễn Dương Ngọc Ánh', '23011500'),

            const SizedBox(height: 20),
            Center(
              child: Text(
                'Ứng dụng này được phát triển bằng Flutter 💙\n'
                'Chúng em xin cảm ơn thầy và các bạn!',
                style: GoogleFonts.vollkorn(
                  fontStyle: FontStyle.italic,
                  color: const Color.fromARGB(255, 21, 21, 21),
                  fontSize: 16,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

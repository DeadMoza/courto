import 'package:flutter/material.dart';

class AboutAppPage extends StatelessWidget {
  const AboutAppPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("حول التطبيق"),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.red[50],
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                "تطبيق كورتو هو تطبيق لحجز ملاعب كرة القدم عبر الهاتف المحمول. "
                "يتيح التطبيق للمستخدمين حجز الملعب المختار لمدة تصل إلى 3 ساعات متتالية عن طريق دفع رسوم حجز صغيرة، "
                "ومن ثم يتم إكمال بقية الدفع مباشرة مع مالك الملعب بعد اللعب.",
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 16),
              Text(
                "ميزات التطبيق:",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "• حجز الملاعب بسهولة عبر الهاتف المحمول.\n"
                "• إمكانية حجز حتى 3 ساعات متتالية.\n"
                "• دفع رسوم الحجز مسبقاً.\n"
                "• إتمام الدفع النهائي مباشرة مع مالك الملعب بعد اللعب.\n"
                "• تجربة سلسة ومريحة للمستخدمين.",
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

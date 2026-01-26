import 'package:flutter/material.dart';

class AboutAppPage extends StatelessWidget {
  const AboutAppPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("حول التطبيق"),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),

              /// LOGO AREA
              Center(
    
                  child: Image.asset(
                    "assets/images/courtoFull.png",
                    width: 150,
                    height: 150,
                  ),
              
              ),

              const SizedBox(height: 20),

              /// VERSION
              Text(
                "الإصدار 2.1.2 ",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.redAccent,
                ),
              ),

              const SizedBox(height: 20),

               Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "تطبيق مخصص لحجز الملاعب الرياضية بسهولة وسرعة. "
                  "يمكنك عرض الملاعب المتاحة، معرفة أوقات اللعب "
                  "وإتمام الحجز مباشرة عبر التطبيق دون أي تعقيد.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: Theme.of(context).colorScheme.onSecondary,
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

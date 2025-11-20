import 'package:flutter/material.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("المساعدة والدعم"),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.red[50],
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 30),

            const Text(
              "نحن هنا لمساعدتك",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              "إذا واجهتك أي مشكلة أثناء استخدام التطبيق، "
              "يمكنك التواصل معنا عبر البريد الإلكتروني أو الواتساب.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, height: 1.4),
            ),

            const SizedBox(height: 30),

            // ---------------- EMAIL SUPPORT ----------------
            _sectionTitle("البريد الإلكتروني"),
            const SizedBox(height: 10),
            _supportTile(
              icon: Icons.email,
              title: "courtolibya@gmail.com",
            ),
            _supportTile(
              icon: Icons.email_outlined,
              title: "help@courto.ly",
            ),

            const SizedBox(height: 30),

            // ---------------- WHATSAPP SUPPORT ----------------
            _sectionTitle("واتساب"),
            const SizedBox(height: 10),
            _supportTile(
              icon: Icons.phone_android,
              title: "+218 93 424 4425",
            ),
            _supportTile(
              icon: Icons.phone_android_outlined,
              title: "+218 92 808 2025",
              
            ),

            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _supportTile({required IconData icon, required String title}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
            
          )
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 16),
              textDirection: TextDirection.ltr,
            ),
          ),
        ],
      ),
    );
  }
}

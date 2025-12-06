import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../../services/auth_service.dart';

final apiUrl = dotenv.env['API_URL'];
final apiKey = dotenv.env['API_KEY'];

class SupportPage extends StatefulWidget {
  const SupportPage({super.key});

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  // Use a map for cleaner object access
  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> issues = [];

  Map<String, dynamic>? selectedCategory;
  Map<String, dynamic>? selectedIssue;

  bool loading = true;
  bool isSending = false;
  bool _isMessageValid = false;

  final TextEditingController messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchCategories();
    // Add listener for message validation
    messageController.addListener(_validateMessage);
  }

  @override
  void dispose() {
    messageController.removeListener(_validateMessage);
    messageController.dispose();
    super.dispose();
  }

  // NEW METHOD: Validates the message controller's text
    void _validateMessage() {
      final text = messageController.text.trim();
      final isValid = text.isNotEmpty;

      setState(() {
        _isMessageValid = isValid;
      });
    }


  // --- API Calls ---

  Future<void> fetchCategories() async {
    if (AuthService.token == null) {
      _showSnackBar("خطأ: لا يوجد رمز مصادقة.", isError: true);
      setState(() => loading = false);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse("${apiUrl}users/getSupportCategories"),
        headers: {
          "Authorization": "Bearer ${AuthService.token}",
          "x-api-key": apiKey ?? "",
        },
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          categories = data.cast<Map<String, dynamic>>();
          loading = false;
        });
      } else {
        final errorData = jsonDecode(response.body);
        _showSnackBar(errorData['error'] ?? "فشل تحميل الفئات", isError: true);
        setState(() => loading = false);
      }
    } catch (e) {
      _showSnackBar("تعذر الاتصال بالخادم. تأكد من اتصالك بالإنترنت.", isError: true);
      setState(() => loading = false);
    }
  }

  void loadIssuesForCategory(Map<String, dynamic> category) {
    setState(() {
      selectedCategory = category;
      // Ensure 'issues' is a List<Map<String, dynamic>>
      issues = (category['issues'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      selectedIssue = null;
      // Reset message validation when category changes
      _isMessageValid = false;
      messageController.clear();
    });
  }

  Future<void> sendSupportRequest() async {
    if (selectedIssue == null) {
      _showSnackBar("يرجى اختيار المشكلة أولاً.");
      return;
    }
    if (!_isMessageValid) {
       _showSnackBar("يرجى إدخال وصف المشكلة.");
       return;
    }

    setState(() => isSending = true);

    final body = {
      "user_id": AuthService.userData?["id"],
      "username":AuthService.userData?["full_name"],
      "phone_number": AuthService.userData?["phone_number"],
      "category": selectedCategory!["name"],
      "issue": selectedIssue!["name"],
      "message": messageController.text.trim(),
    };

    try {
      final response = await http.post(
        Uri.parse("${apiUrl}users/submitSupportTicket"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${AuthService.token}",
          "x-api-key": apiKey ?? "",
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        _showSnackBar("تم إرسال الطلب بنجاح. سنقوم بالرد قريباً.");
        // Reset state after success
        messageController.clear();
        setState(() {
          selectedCategory = null;
          selectedIssue = null;
          issues = [];
          isSending = false;
          _isMessageValid = false;
        });
      } else {
        final errorData = jsonDecode(response.body);
        _showSnackBar(errorData['error'] ?? "حدث خطأ أثناء الإرسال.", isError: true);
        setState(() => isSending = false);
      }
    } catch (e) {
      _showSnackBar("تعذر الاتصال بالخادم.", isError: true);
      setState(() => isSending = false);
    }
  }

  // --- UI Helpers ---

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textDirection: TextDirection.rtl),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  InputDecoration _inputDecoration({required String label, String? counterText}) {
    return InputDecoration(
      labelText: label,
      counterText: counterText, // Hide default counter
      labelStyle: TextStyle(color: Colors.redAccent),
      floatingLabelBehavior: FloatingLabelBehavior.always,
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
    );
  }
  
  // --- Main Build ---

  @override
  Widget build(BuildContext context) {
    // Determine if the Send button should be enabled
    final isButtonEnabled = selectedIssue != null && _isMessageValid && !isSending;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.red[50],
        appBar: AppBar(
          title: const Text("الدعم والمساعدة", style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.redAccent,
          foregroundColor: Colors.white,
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator(color: Colors.redAccent))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title Card/Header
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            "تواصل معنا لحل مشكلتك",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.redAccent,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                              "يرجى اختيار الفئة والمشكلة وتوضيح وصفها بالتفصيل للمساعدة, سوف يتواصل فريق الدعم الفني معك عبر رقم هاتفك او عبر الواتس اب لحل المشكلة في اقرب وقت ممكن.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 15),

                    // ---------------- CATEGORY SELECT ----------------
                    Text("فئة المشكلة:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<Map<String, dynamic>>(
                      value: selectedCategory,
                      isExpanded: true,
                      decoration: _inputDecoration(label: "اختر الفئة"),
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.redAccent),
                      items: categories.map<DropdownMenuItem<Map<String, dynamic>>>(
                        (item) {
                          return DropdownMenuItem(
                            value: item,
                            child: Text(item["name"] ?? "فئة غير معروفة", style: const TextStyle(fontSize: 16)),
                          );
                        },
                      ).toList(),
                      onChanged: (value) {
                        if (value != null) loadIssuesForCategory(value);
                      },
                    ),

                    const SizedBox(height: 20),

                    // ---------------- ISSUE SELECT ----------------
                    if (selectedCategory != null) ...[
                      Text("المشكلة المحددة:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<Map<String, dynamic>>(
                        value: selectedIssue,
                        isExpanded: true,
                        decoration: _inputDecoration(label: "اختر المشكلة"),
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.redAccent),
                        items: issues.map<DropdownMenuItem<Map<String, dynamic>>>(
                          (item) {
                            return DropdownMenuItem(
                              value: item,
                              child: Text(item["name"] ?? "مشكلة غير معروفة", style: const TextStyle(fontSize: 16)),
                            );
                          },
                        ).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedIssue = value;
                            // When issue is selected, refresh message validation
                            _validateMessage(); 
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                    ],

                    // ---------------- MESSAGE INPUT ----------------
                    if (selectedIssue != null) ...[
                      Text("وصف المشكلة:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: messageController,
                        minLines: 4,
                        maxLines: 6,
                        maxLength: 400, // Character limit applied here
                        decoration: _inputDecoration(
                          label: "اكتب تفاصيل المشكلة هنا",
                          counterText: "${messageController.text.length}/400", // Display custom counter
                        ),
                        keyboardType: TextInputType.multiline,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                      ),
                      const SizedBox(height: 30),
                    ],


                    // ---------------- SEND BUTTON ----------------
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        // Button is enabled only if an issue is selected, message is valid, and not currently sending
                        onPressed: isButtonEnabled ? sendSupportRequest : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          disabledBackgroundColor: Colors.grey.shade400, // Styling for disabled state
                        ),
                        child: isSending
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              )
                            : const Text(
                                "إرسال طلب الدعم",
                                style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
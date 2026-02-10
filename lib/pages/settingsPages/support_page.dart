import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../../services/auth_service.dart';
import 'package:courto/l10n/app_localizations.dart';

class SupportPage extends StatefulWidget {
  const SupportPage({super.key});

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> issues = [];

  Map<String, dynamic>? selectedCategory;
  Map<String, dynamic>? selectedIssue;

  bool loading = true;
  bool isSending = false;
  bool _isMessageValid = false;

  final TextEditingController messageController = TextEditingController();

  bool _didFetchOnce = false;

  @override
  void initState() {
    super.initState();
    messageController.addListener(_validateMessage);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didFetchOnce) {
      _didFetchOnce = true;
      fetchCategories(); // ✅ safe here (localizations available)
    }
  }

  @override
  void dispose() {
    messageController.removeListener(_validateMessage);
    messageController.dispose();
    super.dispose();
  }

  void _validateMessage() {
    final text = messageController.text.trim();
    final isValid = text.isNotEmpty;

    setState(() {
      _isMessageValid = isValid;
    });
  }

  // ---------- LOCAL MAPPING (API Arabic -> App localized label) ----------

  String _displayCategoryName(BuildContext context, String apiArabicName) {
    final t = AppLocalizations.of(context)!;

    if (Localizations.localeOf(context).languageCode == 'ar') {
      return apiArabicName;
    }

    switch (apiArabicName) {
      case "الحجز":
        return t.supportCategoryBooking;
      case "الدفع او المحفظة":
        return t.supportCategoryPaymentWallet;
      case "اخرى":
        return t.supportCategoryOther;
      default:
        return apiArabicName;
    }
  }

  String _displayIssueName(BuildContext context, String apiArabicName) {
    final t = AppLocalizations.of(context)!;

    if (Localizations.localeOf(context).languageCode == 'ar') {
      return apiArabicName;
    }

    switch (apiArabicName) {
      case "سعر الحجز الظاهر مختلف عن السعر المدفوع":
        return t.supportIssuePriceMismatch;
      case "هناك تعارض من خارج التطبيق مع حجزي":
        return t.supportIssueExternalConflict;
      case "اريد الغاء الحجز بسبب ظرف معين":
        return t.supportIssueCancelDueToCircumstances;
      case "لا يوجد رد من صاحب الملعب":
        return t.supportIssueNoOwnerResponse;
      case "لم يتم شحن المحفظة رغم خصم القيمة":
        return t.supportIssueWalletNotChargedDeducted;
      case "القيمة المدفوعة اكثر من القيمة الموضحة":
        return t.supportIssuePaidMoreThanShown;
      case "المحفظة مشحونة ولكن لا يمكنني الحجز":
        return t.supportIssueWalletChargedCantBook;
      case "خطأ عند شحن المحفظة":
        return t.supportIssueWalletChargeError;
      case "قيمة الارجاع ناقصة او لم يتم ارجاع القيمة الي المحفظة بعد الغاء حجزي":
        return t.supportIssueRefundMissingOrPartial;
      case "اريد تغيير رقم الهاتف المربوط بحسابي":
        return t.supportIssueChangePhoneNumber;
      case "التطبيق لا يشتغل جيدا في جهازي":
        return t.supportIssueAppNotWorkingWell;
      case "لم اتحصل علي اشعارات":
        return t.supportIssueNoNotifications;
      case "اريد ازالة حسابي من التطبيق":
        return t.supportIssueDeleteAccount;
      case "الملعب مقفل عند وصولي في موعد الحجز":
        return t.supportIssueFieldClosedOnArrival;
      case "الملعب في حالة سيئة او ليس مثل الصور المعروضة":
        return t.supportIssueFieldBadCondition;
      case "َمشكلة غير مذكورة":
        return t.supportIssueNotListed;
      default:
        return apiArabicName;
    }
  }

  // --- API Calls ---

  Future<void> fetchCategories() async {
    final t = AppLocalizations.of(context)!;

    final apiUrl = dotenv.env['API_URL'];
    final apiKey = dotenv.env['API_KEY'];

    if (apiUrl == null || apiUrl.isEmpty) {
      setState(() => loading = false);
      return;
    }

    if (AuthService.token == null) {
      _showSnackBar(t.supportErrorNoAuth, isError: true);
      setState(() => loading = false);
      return;
    }

    try {
      final response = await http
          .get(
            Uri.parse("${apiUrl}users/getSupportCategories"),
            headers: {
              "Authorization": "Bearer ${AuthService.token}",
              "x-api-key": apiKey ?? "",
            },
          )
          .timeout(const Duration(seconds: 20)); // ✅ avoid infinite wait

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          categories = data.cast<Map<String, dynamic>>();
          loading = false;
        });
      } else {
        final errorData = jsonDecode(response.body);
        _showSnackBar(errorData['error'] ?? t.supportErrorLoadCategories, isError: true);
        setState(() => loading = false);
      }
    } catch (e) {
      _showSnackBar(t.supportErrorInternet, isError: true);
      setState(() => loading = false);
    }
  }

  void loadIssuesForCategory(Map<String, dynamic> category) {
    setState(() {
      selectedCategory = category;
      issues = (category['issues'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      selectedIssue = null;
      _isMessageValid = false;
      messageController.clear();
    });
  }

  Future<void> sendSupportRequest() async {
    final t = AppLocalizations.of(context)!;

    final apiUrl = dotenv.env['API_URL'];
    final apiKey = dotenv.env['API_KEY'];

    if (apiUrl == null || apiUrl.isEmpty) {
      return;
    }

    if (selectedIssue == null) {
      _showSnackBar(t.supportSelectIssueFirst);
      return;
    }
    if (!_isMessageValid) {
      _showSnackBar(t.supportEnterDescription);
      return;
    }

    setState(() => isSending = true);

    final body = {
      "user_id": AuthService.userData?["id"],
      "username": AuthService.userData?["full_name"],
      "phone_number": AuthService.userData?["phone_number"],
      "category": selectedCategory!["name"], // keep Arabic to backend
      "issue": selectedIssue!["name"], // keep Arabic to backend
      "message": messageController.text.trim(),
    };

    try {
      final response = await http
          .post(
            Uri.parse("${apiUrl}users/submitSupportTicket"),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer ${AuthService.token}",
              "x-api-key": apiKey ?? "",
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        _showSnackBar(t.supportSentSuccess);

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
        _showSnackBar(errorData['error'] ?? t.supportErrorSending, isError: true);
        setState(() => isSending = false);
      }
    } catch (e) {
      _showSnackBar(t.supportErrorServer, isError: true);
      setState(() => isSending = false);
    }
  }

  // --- UI Helpers ---

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textDirection: Directionality.of(context)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  InputDecoration _inputDecoration({required String label, String? counterText}) {
    return InputDecoration(
      labelText: label,
      counterText: counterText,
      labelStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
      floatingLabelBehavior: FloatingLabelBehavior.always,
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isButtonEnabled = selectedIssue != null && _isMessageValid && !isSending;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(t.supportTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
      ),
      body: loading
          ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          t.supportHeaderTitle,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          t.supportHeaderDescription,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),

                  Text(
                    t.supportCategoryLabel,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<Map<String, dynamic>>(
                    value: selectedCategory,
                    isExpanded: true,
                    decoration: _inputDecoration(label: t.supportSelectCategoryHint),
                    icon: Icon(Icons.arrow_drop_down, color: Theme.of(context).colorScheme.primary),
                    items: categories.map<DropdownMenuItem<Map<String, dynamic>>>((item) {
                      final apiName = (item["name"] ?? "") as String;
                      return DropdownMenuItem(
                        value: item,
                        child: Text(
                          apiName.isNotEmpty ? _displayCategoryName(context, apiName) : t.supportUnknownCategory,
                          style: const TextStyle(fontSize: 16),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) loadIssuesForCategory(value);
                    },
                  ),

                  const SizedBox(height: 20),

                  if (selectedCategory != null) ...[
                    Text(
                      t.supportIssueLabel,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<Map<String, dynamic>>(
                      value: selectedIssue,
                      isExpanded: true,
                      decoration: _inputDecoration(label: t.supportSelectIssueHint),
                      icon: Icon(Icons.arrow_drop_down, color: Theme.of(context).colorScheme.primary),
                      items: issues.map<DropdownMenuItem<Map<String, dynamic>>>((item) {
                        final apiName = (item["name"] ?? "") as String;
                        return DropdownMenuItem(
                          value: item,
                          child: Text(
                            apiName.isNotEmpty ? _displayIssueName(context, apiName) : t.supportUnknownIssue,
                            style: const TextStyle(fontSize: 16),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedIssue = value;
                          _validateMessage();
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                  ],

                  if (selectedIssue != null) ...[
                    Text(
                      t.supportMessageLabel,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: messageController,
                      minLines: 4,
                      maxLines: 6,
                      maxLength: 400,
                      decoration: _inputDecoration(
                        label: t.supportMessageHint,
                        counterText: "${messageController.text.length}/400",
                      ),
                      keyboardType: TextInputType.multiline,
                      textDirection: Directionality.of(context),
                      textAlign: TextAlign.start,
                    ),
                    const SizedBox(height: 30),
                  ],

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isButtonEnabled ? sendSupportRequest : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        disabledBackgroundColor: Colors.grey.shade400,
                      ),
                      child: isSending
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Theme.of(context).colorScheme.onPrimary,
                                strokeWidth: 3,
                              ),
                            )
                          : Text(
                              t.supportSendButton,
                              style: TextStyle(
                                fontSize: 18,
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

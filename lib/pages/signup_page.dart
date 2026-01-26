import 'package:flutter/material.dart';
import 'otp_page.dart';
import 'login_page.dart';
import 'package:flutter/gestures.dart';


class SignupPage extends StatefulWidget {
  final String? errorMessage; // optional error passed back

  const SignupPage({super.key, this.errorMessage});

  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final passController = TextEditingController();
  final confirmPassController = TextEditingController();
  bool loading = false;
  bool showPassword = false;
  bool showConfirmPassword = false;

  @override
  void initState() {
    super.initState();
    if (widget.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showError(widget.errorMessage!);
      });
    }
  }

  void _goToOtp() async {
    FocusScope.of(context).unfocus();

    // check empty fields
    if (nameController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty ||
        passController.text.trim().isEmpty ||
        confirmPassController.text.trim().isEmpty) {
      _showError("الرجاء ملء جميع الحقول");
      return;
    }

    // Validate full name: must be in Arabic and contain a space
    String name = nameController.text.trim();
    final arabicNameRegex = RegExp(r'^[\u0600-\u06FF\s]+$'); // Arabic letters and spaces
    if (!arabicNameRegex.hasMatch(name) || !name.contains(' ')) {
      _showError("الرجاء إدخال اسم كامل باللغة العربية");
      return;
    }

    // Validate password: 8-16 chars, at least 1 letter, optionally numbers/symbols
    String password = passController.text;
    final passwordRegex = RegExp(r'^(?=.*[A-Za-z])[A-Za-z0-9!@#$%^&*()_+=-]{8,18}$');
    if (!passwordRegex.hasMatch(password)) {
      _showError(
          "كلمة المرور يجب أن تكون بين 8 و 18 حرفًا وتحتوي على أحرف وأرقام أو رموز اختيارية");
      return;
    }

    // check password match
    if (passController.text != confirmPassController.text) {
      _showError("كلمتا المرور غير متطابقتين");
      return;
    }

    // Normalize phone number
    String phone = phoneController.text.trim();
    if (phone.startsWith("09")) {
      phone = "218${phone.substring(1)}";
    } else if (phone.startsWith("9")) {
      phone = "218$phone";
    } else if (phone.startsWith("0")) {
      phone = "218${phone.substring(1)}";
    } else if (!phone.startsWith("218")) {
      phone = "218$phone";
    }

    // Validate phone number format (Libyan numbers starting with 2189)
    if (!RegExp(r'^2189[0-9]{8}$').hasMatch(phone)) {
      _showError("الرجاء إدخال رقم هاتف صحيح يبدأ بـ 2189");
      return;
    }

    final error = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OtpPage(
          phoneNumber: phone,
          fullName: name,
          password: password,
        ),
      ),
    );

    if (error != null && error is String) {
      _showError(error);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textDirection: TextDirection.rtl),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  void _showTermsDialog() {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text(
        "شروط الاستخدام",
        textDirection: TextDirection.rtl,
      ),
      content: SingleChildScrollView(
        child:Text(
  'استخدام تطبيق كورتو (courto) وأحكامه\n'
  'آخر تحديث: 2025-12-13\n'
  'يرجى قراءة هذه الشروط بعناية قبل استخدام تطبيق كورتو (courto)، حيث أن استخدامكم للتطبيق يعني موافقتكم الكاملة وغير المشروطة على جميع البنود التالية.\n'
  '⸻\n'
  '1. التعريفات\n'
  '• التطبيق: تطبيق كورتو (courto) الخاص بحجز الملاعب الرياضية (كرة قدم، سلة، وغيرها).\n'
  '• المستخدم: كل شخص يقوم بتحميل التطبيق أو إنشاء حساب أو استخدامه لحجز ملعب.\n'
  '• صاحب الملعب: الشخص أو الجهة المالكة أو المسؤولة عن إدارة الملعب المعروض داخل التطبيق.\n'
  '• رسوم الحجز المبدئية: المبلغ الذي يدفعه المستخدم عبر التطبيق لتأكيد الحجز يحدده صاحب الملعب ويحق له تغييره في اي وقت قبل الحجز.\n'
  '• المبلغ المتبقي: المبلغ الذي يدفعه المستخدم لصاحب الملعب مباشرة عند الوصول إلى الموقع او بعد اللعب حسب طلب صاحب الملعب.\n'
  '⸻\n'
  '2. آلية الحجز والدفع\n'
  '1. يقوم المستخدم بشحن المحفظة الخاصة به في التطبيق ومن ثم, اختيار الملعب والوقت والتاريخ المناسب للحجز من خلال التطبيق.\n'
  '2. بعد إرسال الطلب، لا يتم خصم أي مبلغ مالي مباشرة من المحفظة الخاصة بالمستخدم حتى يقوم صاحب الملعب بقبول الحجز.\n'
  '3. بمجرد قبول صاحب الملعب، يتم خصم رسوم الحجز المبدئية من المحفظة الخاصة بالمستخدم.\n'
  '4. يُعتبر الحجز مؤكدًا بعد قبول صاحب الملعب ونجاح خصم المبلغ المبدئي، ويتلقى المستخدم إشعارًا بالتأكيد.\n'
  '5. عند حضور المستخدم إلى الملعب، يقوم بدفع المبلغ المتبقي مباشرة لصاحب الملعب حسب السعر المعروض في التطبيق.\n'
  '6. يتحمل المستخدم مسؤولية التأكد من تفاصيل الحجز قبل الإرسال (الوقت، الموقع، نوع الملعب).\n'
  '7. لا يمكن للمستخدم إنشاء حجز جديد ما لم يتم قبول أو رفض الحجز "المعلق" السابق، وذلك لمنع تكرار الطلبات غير المؤكدة وضمان عدالة نظام الحجز.\n'
  '⸻\n'
  '3. الاشتراك الشهري\n'
  '1. يتيح تطبيق كورتو (courto) خيار الاشتراك الشهري في بعض الملاعب المشاركة، وذلك وفقًا لتفعيل هذه الخدمة من قبل صاحب الملعب.\n'
  '2. يمنح الاشتراك الشهري المستخدم حجزًا ثابتًا ليوم واحد في الأسبوع (مثل الأحد، الاثنين، ...)، لمدة شهر كامل أي أربع جلسات (أربعة أسابيع متتالية).\n'
  '3. آلية الدفع والتقييم:\n'
  '• يدفع المستخدم رسومًا مبدئية عبر التطبيق لتأكيد الاشتراك، وتُحسب رسوم الاشتراك المبدئية حسب عدد الساعات الكلي.\n'
  '• يُدفع باقي المبلغ مباشرة لصاحب الملعب عند أول جلسة وفقًا للسعر المحدد في صفحة الملعب داخل التطبيق.\n'
  '> ملاحظة: تعتبر المبالغ المدفوعة عبر التطبيق رسوم تأكيد للاشتراك الشهري ولا تُسترد إلا وفق الحالات المحددة أدناه.\n'
  '4. الإلغاء والاسترجاع:\n'
  '• يُطبق على الاشتراك الشهري نفس أحكام الإلغاء والاسترجاع المعمول بها في البند (4) من هذه الشروط.\n'
  '• لا يمكن للمستخدم إلغاء الاشتراك أو استرجاع الرسوم المبدئية بعد قبول الاشتراك من صاحب الملعب أو بعد بدء أول جلسة.\n'
  '• يحق لصاحب الملعب الإلغاء أو تعديل الجلسات في حالات الضرورة (مثل سوء الأحوال الجوية أو الصيانة الطارئة)، ويتم استرجاع المبلغ المقابل لتلك الجلسة فقط إلى محفظة المستخدم.\n'
  '5. حضور المستخدم:\n'
  '• في حال غياب المستخدم عن أي جلسة من جلسات الاشتراك لأي سبب، لا يحق له المطالبة بجلسة بديلة أو استرجاع أي مبلغ.\n'
  '6. لا يجوز نقل أو تأجير الاشتراك الشهري أو مشاركته مع أطراف أخرى بدون موافقة مسبقة من صاحب الملعب.\n'
  '7. يحتفظ التطبيق ومالكو الملاعب بحق تعديل أو إيقاف خدمة الاشتراك الشهري في أي وقت مع إشعار مسبق للمستخدمين، مع احترام حقوق الاسترجاع للجلسات غير المنفذة.\n'
  '⸻\n'
  '4. الإلغاء والاسترجاع\n'
  '1. لا يمكن للمستخدم إلغاء الحجز إلا بعد مرور 20 دقيقة على إنشاء الحجز، وذلك لمنع تكرار عمليات الإلغاء العشوائية.\n'
  '2. إذا تم قبول الحجز من قبل صاحب الملعب فلا يمكن للمستخدم إلغاؤه أو استرجاع المبلغ المبدئي.\n'
  '3. في حال قبول الحجز من صاحب الملعب ثم عدم حضور المستخدم في الوقت المحدد أو تغييره، لا تُسترد رسوم الحجز المبدئية.\n'
  '4. يحق لصاحب الملعب إلغاء الحجز في حالات الضرورة (مثل سوء الأحوال الجوية أو الصيانة الطارئة). في هذه الحالة يتم استرجاع كامل المبلغ المبدئي إلى محفظة المستخدم.\n'
  '5. يحتفظ التطبيق بحق تعليق أو حظر أي مستخدم يقوم بسلوك مضر أو تكرار إلغاء الحجز بشكل يضر بالنظام.\n'
  '⸻\n'
  '5. مسؤوليات المستخدم\n'
  '1. تقديم بيانات صحيحة أثناء التسجيل والحجز.\n'
  '2. الالتزام بالحضور في الوقت المحدد واحترام تعليمات وقواعد استخدام الملعب.\n'
  '3. يُمنع نقل أو تأجير الحجز لشخص آخر دون موافقة مسبقة من صاحب الملعب.\n'
  '4. يتحمل المستخدم أي أضرار يتسبب بها أثناء استخدام الملعب.\n'
  '⸻\n'
  '6. مسؤوليات أصحاب الملاعب\n'
  '1. الالتزام بتوفير الملعب في الوقت المحدد.\n'
  '2. تحمل المسؤولية عن أي إلغاء أو تغيير بعد تأكيد الحجز.\n'
  '3. عرض الأسعار بشكل واضح وشفاف دون رسوم مخفية.\n'
  '⸻\n'
  '7. مسؤولية تطبيق كورتو (courto)\n'
  '1. يعمل التطبيق كوسيط إلكتروني فقط بين المستخدمين وأصحاب الملاعب.\n'
  '2. لا يتحمل التطبيق مسؤولية عن:\n'
  '• جودة أو نظافة أو جاهزية الملاعب.\n'
  '• أي نزاع مالي بين المستخدم وصاحب الملعب.\n'
  '• أي ضرر مادي أو جسدي أثناء استخدام الملعب.\n'
  '3. لا يتحمل التطبيق مسؤولية الأخطاء الناتجة عن إدخال بيانات غير صحيحة.\n'
  '4. يحتفظ التطبيق بحق تعليق أو حذف الحسابات المخالفة أو المسيئة.\n'
  '⸻\n'
  '8. الخصوصية وحماية البيانات\n'
  '1. يتم حفظ بيانات المستخدمين بشكل آمن وفق سياسة الخصوصية.\n'
  '2. لا تُشارك البيانات مع أي طرف ثالث إلا بموافقة المستخدم أو بأمر قانوني.\n'
  '3. يحق للتطبيق استخدام البيانات الإحصائية المجهولة لتحسين الخدمات.\n'
  '⸻\n'
  '9. الملكية الفكرية\n'
  'جميع المحتويات والعلامات التجارية والتصاميم داخل تطبيق كورتو مملوكة له ومحميّة قانونيًا. يُمنع نسخ أو إعادة استخدام أي جزء منها دون إذن مسبق.\n'
  '⸻\n'
  '10. التعديلات على الشروط\n'
  'يحتفظ تطبيق كورتو بحق تعديل هذه الشروط في أي وقت. يعتبر استمرار المستخدم في استخدام التطبيق بعد نشر التعديلات موافقة ضمنية على النسخة المحدّثة.\n'
  '⸻\n'
  '11. القوانين المطبقة وحل النزاعات\n'
  'تخضع هذه الشروط للقوانين المعمول بها في دولة ليبيا. في حال حدوث أي نزاع، تكون الجهات القضائية الليبية المختصة هي المرجع الحصري للفصل فيه.\n'
  '⸻\n'
  '12. التواصل\n'
  'للاستفسارات أو الشكاوى:\n'
  'courtolibya@gmail.com',
  textDirection: TextDirection.rtl,
),

      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("إغلاق"),
        ),
      ],
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    "assets/images/courtoFull.png",
                    width: 150,
                    height: 150,
                  ),
                  const SizedBox(height: 24),

                  // Full Name
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: "الاسم الكامل",
                      prefixIcon: Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.onPrimary,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Phone
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(
                      labelText: "رقم الهاتف",
                      prefixIcon: Icon(Icons.phone, color: Theme.of(context).colorScheme.primary),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.onPrimary,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Password
                  TextField(
                    controller: passController,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.ltr,
                    obscureText: !showPassword,
                    decoration: InputDecoration(
                      labelText: "كلمة المرور",
                      prefixIcon: Icon(Icons.lock_outline, color: Theme.of(context).colorScheme.primary),
                      suffixIcon: IconButton(
                        icon: Icon(
                          showPassword ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() => showPassword = !showPassword);
                        },
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.onPrimary,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Confirm Password
                  TextField(
                    controller: confirmPassController,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.ltr,
                    obscureText: !showConfirmPassword,
                    decoration: InputDecoration(
                      labelText: "تأكيد كلمة المرور",
                      prefixIcon:
                         Icon(Icons.lock, color: Theme.of(context).colorScheme.primary),
                      suffixIcon: IconButton(
                        icon: Icon(
                          showConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() =>
                              showConfirmPassword = !showConfirmPassword);
                        },
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.onPrimary,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  RichText(
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSecondary,
                        ),
                        children: [
                          const TextSpan(text: "بإنشاء حساب، فإنك توافق على ", style: TextStyle(fontFamily: "Changa")),
                          TextSpan(
                            text: "شروط الاستخدام",
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                              fontFamily: "Changa"
                            ),
                            recognizer: TapGestureRecognizer()..onTap = _showTermsDialog,
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),


                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: loading ? null : _goToOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        disabledBackgroundColor: Theme.of(context).colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      child: const Text(
                        "متابعة",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Switch to login
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      );
                    },
                    child: Text(
                      "لديك حساب من قبل؟ تسجيل الدخول",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
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

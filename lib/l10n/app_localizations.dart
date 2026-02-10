import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// No description provided for @appLanguage.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get appLanguage;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get arabic;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get darkMode;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumber;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @continueText.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueText;

  /// No description provided for @haveAccountLogin.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Log in'**
  String get haveAccountLogin;

  /// No description provided for @signupAgreePrefix.
  ///
  /// In en, this message translates to:
  /// **'By creating an account, you agree to '**
  String get signupAgreePrefix;

  /// No description provided for @termsTitle.
  ///
  /// In en, this message translates to:
  /// **'Terms of use'**
  String get termsTitle;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @signupErrorFillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all fields'**
  String get signupErrorFillAllFields;

  /// No description provided for @signupErrorArabicFullName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your full name in Arabic'**
  String get signupErrorArabicFullName;

  /// No description provided for @signupErrorPasswordRules.
  ///
  /// In en, this message translates to:
  /// **'Password must be 8 to 18 characters and contain letters, with optional numbers or symbols'**
  String get signupErrorPasswordRules;

  /// No description provided for @signupErrorPasswordsNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get signupErrorPasswordsNotMatch;

  /// No description provided for @signupErrorPhoneFormat.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid phone number starting with 2189'**
  String get signupErrorPhoneFormat;

  /// No description provided for @termsBody.
  ///
  /// In en, this message translates to:
  /// **'Use of Courto (courto) App – Terms and Conditions\nLast update: 2025-12-13\n\nPlease read these terms carefully before using the Courto (courto) app. By using the app, you fully and unconditionally agree to all terms below.\n\n1. Definitions\n• App: Courto (courto) sports booking app (football, basketball, etc.).\n• User: anyone who downloads the app, creates an account, or uses it to book.\n• Venue owner: the person/entity responsible for the venue listed in the app.\n• Initial booking fee: amount paid via the app to confirm a booking, set by the venue owner and may change before booking.\n• Remaining amount: paid directly to the venue owner on arrival or after play as requested.\n\n2. Booking and payment\n1. User tops up their wallet then selects venue, date, and time.\n2. No amount is deducted until the venue owner accepts.\n3. Once accepted, the initial fee is deducted.\n4. Booking is confirmed after acceptance and successful deduction.\n5. User pays the remaining amount directly to the venue owner.\n6. User is responsible for verifying booking details before submitting.\n7. User cannot create a new booking until the previous pending booking is accepted or rejected.\n\n3. Monthly subscription\n1. Some venues may offer monthly subscription if enabled by the venue owner.\n2. Subscription grants one fixed weekly session for a month (four consecutive weeks).\n3. Payment: initial confirmation fee via the app (based on total hours) and the remaining amount paid directly to the owner at the first session.\nNote: amounts paid via the app are confirmation fees and are refundable only in cases below.\n4. Cancellation/refund follows section (4). User cannot cancel or refund after acceptance or after the first session starts.\n5. No-shows are not eligible for makeup sessions or refunds.\n6. Subscription cannot be transferred/shared without owner approval.\n7. App/owners may modify/stop subscription with prior notice while respecting refunds for non-delivered sessions.\n\n4. Cancellation and refunds\n1. User can cancel only after 20 minutes from creating the booking.\n2. If accepted, user cannot cancel or refund the initial fee.\n3. If user does not attend after acceptance, the initial fee is not refunded.\n4. Owner may cancel for necessity (weather/maintenance); in that case the full initial fee is refunded to the user wallet.\n5. App may suspend/ban users for harmful behavior or repeated disruptive cancellations.\n\n5. User responsibilities\n1. Provide correct data during registration/booking.\n2. Attend on time and follow venue rules.\n3. No transfer/rent of booking without owner approval.\n4. User is responsible for any damages caused.\n\n6. Venue owner responsibilities\n1. Provide the venue at the scheduled time.\n2. Responsible for cancellations/changes after confirmation.\n3. Show pricing clearly without hidden fees.\n\n7. Courto app responsibility\n1. App acts as an electronic intermediary between users and venue owners.\n2. App is not responsible for venue quality/cleanliness/readiness, financial disputes, or injuries/damages during use.\n3. App is not responsible for errors due to incorrect user input.\n4. App may suspend/delete violating accounts.\n\n8. Privacy and data protection\n1. User data is stored securely under the privacy policy.\n2. Data is not shared with third parties except with user consent or legal order.\n3. App may use anonymous statistics to improve services.\n\n9. Intellectual property\nAll content/brands/designs in Courto are owned and legally protected; copying/reuse without permission is prohibited.\n\n10. Changes to terms\nCourto may update these terms anytime; continued use after updates implies acceptance.\n\n11. Governing law and disputes\nThese terms are governed by the laws of Libya; Libyan courts have exclusive jurisdiction.\n\n12. Contact\nFor inquiries/complaints:\ncourtolibya@gmail.com'**
  String get termsBody;

  /// No description provided for @pleaseLogin.
  ///
  /// In en, this message translates to:
  /// **'Please log in'**
  String get pleaseLogin;

  /// No description provided for @phoneNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'No phone number'**
  String get phoneNotAvailable;

  /// No description provided for @bookingHistory.
  ///
  /// In en, this message translates to:
  /// **'Booking history'**
  String get bookingHistory;

  /// No description provided for @favoriteFields.
  ///
  /// In en, this message translates to:
  /// **'Favorite fields'**
  String get favoriteFields;

  /// No description provided for @supportHelp.
  ///
  /// In en, this message translates to:
  /// **'Support & help'**
  String get supportHelp;

  /// No description provided for @chargeWallet.
  ///
  /// In en, this message translates to:
  /// **'Charge wallet'**
  String get chargeWallet;

  /// No description provided for @aboutApp.
  ///
  /// In en, this message translates to:
  /// **'About the app'**
  String get aboutApp;

  /// No description provided for @visibilityMode.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get visibilityMode;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logout;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get login;

  /// No description provided for @logoutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get logoutConfirmTitle;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @otpTitle.
  ///
  /// In en, this message translates to:
  /// **'Verification Code'**
  String get otpTitle;

  /// No description provided for @otpSentTo.
  ///
  /// In en, this message translates to:
  /// **'We sent a verification code to {phone}'**
  String otpSentTo(Object phone);

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @otpResendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get otpResendCode;

  /// No description provided for @otpResendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend in {seconds}s'**
  String otpResendIn(Object seconds);

  /// No description provided for @otpSmsMessage.
  ///
  /// In en, this message translates to:
  /// **'Your verification code is: {code}'**
  String otpSmsMessage(Object code);

  /// No description provided for @errorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String errorPrefix(Object message);

  /// No description provided for @otpErrorToken.
  ///
  /// In en, this message translates to:
  /// **'Failed to get token'**
  String get otpErrorToken;

  /// No description provided for @otpErrorSendCode.
  ///
  /// In en, this message translates to:
  /// **'Failed to send verification code'**
  String get otpErrorSendCode;

  /// No description provided for @otpErrorRasaelLogin.
  ///
  /// In en, this message translates to:
  /// **'Failed to login to SMS service'**
  String get otpErrorRasaelLogin;

  /// No description provided for @otpErrorInvalidCode.
  ///
  /// In en, this message translates to:
  /// **'Incorrect verification code'**
  String get otpErrorInvalidCode;

  /// No description provided for @otpAccountCreatedDefault.
  ///
  /// In en, this message translates to:
  /// **'Account created successfully.'**
  String get otpAccountCreatedDefault;

  /// No description provided for @otpErrorSignupFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create account'**
  String get otpErrorSignupFailed;

  /// No description provided for @otpErrorDuringSignup.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while creating the account'**
  String get otpErrorDuringSignup;

  /// No description provided for @loginErrorFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get loginErrorFailed;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Network error. Please check your internet connection.'**
  String get networkError;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @newUserCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'New user? Create an account'**
  String get newUserCreateAccount;

  /// No description provided for @landingFeaturedDefault1.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Courto!'**
  String get landingFeaturedDefault1;

  /// No description provided for @landingFeaturedDefault2.
  ///
  /// In en, this message translates to:
  /// **'Top up • Book • Play'**
  String get landingFeaturedDefault2;

  /// No description provided for @tennis.
  ///
  /// In en, this message translates to:
  /// **'Tennis'**
  String get tennis;

  /// No description provided for @padel.
  ///
  /// In en, this message translates to:
  /// **'Padel'**
  String get padel;

  /// No description provided for @offersDiscounts.
  ///
  /// In en, this message translates to:
  /// **'Offers & Discounts'**
  String get offersDiscounts;

  /// No description provided for @matchesPlayed.
  ///
  /// In en, this message translates to:
  /// **'Matches played'**
  String get matchesPlayed;

  /// No description provided for @bookField.
  ///
  /// In en, this message translates to:
  /// **'Book a field'**
  String get bookField;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @fieldDefaultName.
  ///
  /// In en, this message translates to:
  /// **'Unnamed field'**
  String get fieldDefaultName;

  /// No description provided for @discountBadge.
  ///
  /// In en, this message translates to:
  /// **'{percent}% off'**
  String discountBadge(Object percent);

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'LYD {value}'**
  String currency(Object value);

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navFields.
  ///
  /// In en, this message translates to:
  /// **'Fields'**
  String get navFields;

  /// No description provided for @navMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get navMap;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @errorLoadFields.
  ///
  /// In en, this message translates to:
  /// **'Failed to load fields'**
  String get errorLoadFields;

  /// No description provided for @errorConnection.
  ///
  /// In en, this message translates to:
  /// **'Connection failed'**
  String get errorConnection;

  /// No description provided for @mapPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'You must log in and allow location access to view fields on the map.'**
  String get mapPermissionRequired;

  /// No description provided for @mapNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'The map is currently unavailable. We will try again at the beginning of the month.'**
  String get mapNotAvailable;

  /// No description provided for @pricePerHour.
  ///
  /// In en, this message translates to:
  /// **'{price} LYD / hour'**
  String pricePerHour(Object price);

  /// No description provided for @filterCityTitle.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get filterCityTitle;

  /// No description provided for @filterTypeTitle.
  ///
  /// In en, this message translates to:
  /// **'Field type'**
  String get filterTypeTitle;

  /// No description provided for @filterSortTitle.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get filterSortTitle;

  /// No description provided for @loadingCities.
  ///
  /// In en, this message translates to:
  /// **'Loading cities...'**
  String get loadingCities;

  /// No description provided for @sortDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get sortDistance;

  /// No description provided for @sortPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get sortPrice;

  /// No description provided for @filterTooltip.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filterTooltip;

  /// No description provided for @typeAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get typeAll;

  /// No description provided for @typeFootball.
  ///
  /// In en, this message translates to:
  /// **'Football'**
  String get typeFootball;

  /// No description provided for @typeBasketball.
  ///
  /// In en, this message translates to:
  /// **'Basketball'**
  String get typeBasketball;

  /// No description provided for @typeTennis.
  ///
  /// In en, this message translates to:
  /// **'Tennis'**
  String get typeTennis;

  /// No description provided for @typePadel.
  ///
  /// In en, this message translates to:
  /// **'Padel'**
  String get typePadel;

  /// No description provided for @typePadbol.
  ///
  /// In en, this message translates to:
  /// **'Padbol'**
  String get typePadbol;

  /// No description provided for @typeKarting.
  ///
  /// In en, this message translates to:
  /// **'Karting'**
  String get typeKarting;

  /// No description provided for @typePaintball.
  ///
  /// In en, this message translates to:
  /// **'Paintball'**
  String get typePaintball;

  /// No description provided for @typeGolf.
  ///
  /// In en, this message translates to:
  /// **'Golf'**
  String get typeGolf;

  /// No description provided for @typeVolleyball.
  ///
  /// In en, this message translates to:
  /// **'Volleyball'**
  String get typeVolleyball;

  /// No description provided for @activeCity.
  ///
  /// In en, this message translates to:
  /// **'City: {city}'**
  String activeCity(Object city);

  /// No description provided for @activeType.
  ///
  /// In en, this message translates to:
  /// **'Type: {type}'**
  String activeType(Object type);

  /// No description provided for @activeSort.
  ///
  /// In en, this message translates to:
  /// **'Sort: {sort}'**
  String activeSort(Object sort);

  /// No description provided for @kmDistance.
  ///
  /// In en, this message translates to:
  /// **'{km} km'**
  String kmDistance(Object km);

  /// No description provided for @discountPercent.
  ///
  /// In en, this message translates to:
  /// **'-{percent}%'**
  String discountPercent(Object percent);

  /// No description provided for @bookingAndPrice.
  ///
  /// In en, this message translates to:
  /// **'Booking: {booking} | {price}'**
  String bookingAndPrice(Object booking, Object price);

  /// No description provided for @bookingAndPricePerHour.
  ///
  /// In en, this message translates to:
  /// **'Booking: {booking} | {price}/hour'**
  String bookingAndPricePerHour(Object booking, Object price);

  /// No description provided for @errorWithMessage.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String errorWithMessage(Object message);

  /// No description provided for @noFieldsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No {type} fields available right now in {city}.'**
  String noFieldsAvailable(Object type, Object city);

  /// No description provided for @themeTitle.
  ///
  /// In en, this message translates to:
  /// **'Theme mode'**
  String get themeTitle;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @supportTitle.
  ///
  /// In en, this message translates to:
  /// **'Support & Help'**
  String get supportTitle;

  /// No description provided for @supportHeaderTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact us to solve your issue'**
  String get supportHeaderTitle;

  /// No description provided for @supportHeaderDescription.
  ///
  /// In en, this message translates to:
  /// **'Please choose the category and issue and describe it in detail. The support team will contact you via your phone number or WhatsApp as soon as possible.'**
  String get supportHeaderDescription;

  /// No description provided for @supportCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Issue category:'**
  String get supportCategoryLabel;

  /// No description provided for @supportSelectCategoryHint.
  ///
  /// In en, this message translates to:
  /// **'Select category'**
  String get supportSelectCategoryHint;

  /// No description provided for @supportUnknownCategory.
  ///
  /// In en, this message translates to:
  /// **'Unknown category'**
  String get supportUnknownCategory;

  /// No description provided for @supportIssueLabel.
  ///
  /// In en, this message translates to:
  /// **'Selected issue:'**
  String get supportIssueLabel;

  /// No description provided for @supportSelectIssueHint.
  ///
  /// In en, this message translates to:
  /// **'Select issue'**
  String get supportSelectIssueHint;

  /// No description provided for @supportUnknownIssue.
  ///
  /// In en, this message translates to:
  /// **'Unknown issue'**
  String get supportUnknownIssue;

  /// No description provided for @supportMessageLabel.
  ///
  /// In en, this message translates to:
  /// **'Issue description:'**
  String get supportMessageLabel;

  /// No description provided for @supportMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Write issue details here'**
  String get supportMessageHint;

  /// No description provided for @supportSendButton.
  ///
  /// In en, this message translates to:
  /// **'Send support request'**
  String get supportSendButton;

  /// No description provided for @supportSelectIssueFirst.
  ///
  /// In en, this message translates to:
  /// **'Please select an issue first.'**
  String get supportSelectIssueFirst;

  /// No description provided for @supportEnterDescription.
  ///
  /// In en, this message translates to:
  /// **'Please enter the issue description.'**
  String get supportEnterDescription;

  /// No description provided for @supportSentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Request sent successfully. We will reply soon.'**
  String get supportSentSuccess;

  /// No description provided for @supportErrorNoAuth.
  ///
  /// In en, this message translates to:
  /// **'Error: No authentication token.'**
  String get supportErrorNoAuth;

  /// No description provided for @supportErrorLoadCategories.
  ///
  /// In en, this message translates to:
  /// **'Failed to load categories.'**
  String get supportErrorLoadCategories;

  /// No description provided for @supportErrorInternet.
  ///
  /// In en, this message translates to:
  /// **'Could not connect to the server. Check your internet connection.'**
  String get supportErrorInternet;

  /// No description provided for @supportErrorServer.
  ///
  /// In en, this message translates to:
  /// **'Could not connect to the server.'**
  String get supportErrorServer;

  /// No description provided for @supportErrorSending.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while sending.'**
  String get supportErrorSending;

  /// No description provided for @policyTitle.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get policyTitle;

  /// No description provided for @policyBody.
  ///
  /// In en, this message translates to:
  /// **'Courto (courto) App Terms & Conditions\nLast update: 2025-12-13\nPlease read these terms carefully before using the Courto (courto) app. Your use of the app indicates your full and unconditional acceptance of all the following clauses.\n⸻\n1. Definitions\n• App: The Courto (courto) application for booking sports fields (football, basketball, etc.).\n• User: Any person who downloads the app, creates an account, or uses it to book a field.\n• Field Owner: The person or entity responsible for managing the field listed in the app.\n• Initial Booking Fee: The amount paid via the app to confirm the booking. It is set by the field owner and can be changed before booking.\n• Remaining Amount: The amount paid directly to the field owner on arrival or after playing, depending on the field owner’s policy.\n⸻\n2. Booking & Payment Process\n1. The user tops up their wallet in the app, then selects the field, time, and date for booking.\n2. After sending the request, no funds are deducted until the field owner accepts the booking.\n3. Once accepted, the initial booking fee is deducted from the user’s wallet.\n4. The booking is confirmed after acceptance and successful deduction, and the user receives a confirmation notification.\n5. Upon arriving at the field, the user pays the remaining amount directly to the field owner based on the price shown in the app.\n6. The user is responsible for verifying booking details before submission (time, location, field type).\n7. The user cannot create a new booking until the previous pending booking is accepted or rejected to prevent duplicate requests and ensure fairness.\n⸻\n3. Monthly Subscription\n1. The app offers a monthly subscription option for participating fields, subject to field owner activation.\n2. The subscription gives the user a fixed weekly booking (e.g., Sunday, Monday, etc.) for one month (four consecutive sessions).\n3. Payment:\n• The user pays an initial fee via the app to confirm the subscription, calculated based on the total hours.\n• The remaining amount is paid directly to the field owner at the first session as displayed in the field page.\nNote: Amounts paid via the app are confirmation fees and are refundable only in the cases stated below.\n4. Cancellation & Refund:\n• The same cancellation and refund rules in section (4) apply.\n• The user cannot cancel or refund the initial fee after the subscription is accepted or after the first session begins.\n• The field owner may cancel/adjust sessions for necessary reasons (weather/maintenance). Only the affected session amount is refunded to the user’s wallet.\n5. Attendance:\n• If the user misses any session, they are not entitled to a replacement session or refund.\n6. The subscription cannot be transferred or shared without the field owner’s prior approval.\n7. The app and field owners may modify or stop the subscription service with prior notice while preserving refunds for unfulfilled sessions.\n⸻\n4. Cancellation & Refund\n1. The user can cancel a booking only after 20 minutes of creating it to prevent random cancellations.\n2. If the booking is accepted by the field owner, the user cannot cancel or refund the initial fee.\n3. If the booking is accepted and the user does not attend or changes time, the initial fee is not refunded.\n4. The field owner may cancel in necessary cases (weather/maintenance). In this case, the full initial fee is refunded to the user’s wallet.\n5. The app may suspend/ban any user who harms the system or repeatedly cancels bookings.\n⸻\n5. User Responsibilities\n1. Provide accurate information during registration and booking.\n2. Attend on time and respect field rules.\n3. Do not transfer or rent the booking to another person without field owner approval.\n4. The user is responsible for any damages caused while using the field.\n⸻\n6. Field Owner Responsibilities\n1. Provide the field at the agreed time.\n2. Be responsible for cancellations or changes after confirmation.\n3. Display prices clearly without hidden fees.\n⸻\n7. Courto App Responsibility\n1. The app acts as an electronic intermediary between users and field owners.\n2. The app is not responsible for:\n• Field quality/cleanliness/readiness.\n• Financial disputes between user and field owner.\n• Any physical injury or property damage while using the field.\n3. The app is not responsible for errors caused by incorrect user input.\n4. The app may suspend/delete abusive or violating accounts.\n⸻\n8. Privacy & Data Protection\n1. User data is stored securely under the privacy policy.\n2. Data is not shared with third parties without user consent or legal order.\n3. The app may use anonymous statistical data to improve services.\n⸻\n9. Intellectual Property\nAll content, trademarks, and designs in the Courto app are owned and legally protected. Copying or reuse without permission is prohibited.\n⸻\n10. Changes to Terms\nCourto reserves the right to modify these terms at any time. Continued use after changes indicates acceptance of the updated version.\n⸻\n11. Applicable Law & Disputes\nThese terms are governed by the laws of Libya. Any disputes fall under the jurisdiction of the competent Libyan courts.\n⸻\n12. Contact\nFor inquiries or complaints:\ncourtolibya@gmail.com'**
  String get policyBody;

  /// No description provided for @favoritesTitle.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favoritesTitle;

  /// No description provided for @favoritesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No favorite fields'**
  String get favoritesEmpty;

  /// No description provided for @favoritesLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load favorites'**
  String get favoritesLoadFailed;

  /// No description provided for @favoritesRemoveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove favorite'**
  String get favoritesRemoveFailed;

  /// No description provided for @favoritesRemovedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Removed from favorites'**
  String get favoritesRemovedSuccess;

  /// No description provided for @confirmDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm deletion'**
  String get confirmDeleteTitle;

  /// No description provided for @confirmRemoveFavoriteBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this field from favorites?'**
  String get confirmRemoveFavoriteBody;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @cityLabel.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get cityLabel;

  /// No description provided for @capacityLabel.
  ///
  /// In en, this message translates to:
  /// **'Capacity'**
  String get capacityLabel;

  /// No description provided for @errorConnectionServer.
  ///
  /// In en, this message translates to:
  /// **'Could not connect to the server'**
  String get errorConnectionServer;

  /// No description provided for @bookingHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking History'**
  String get bookingHistoryTitle;

  /// No description provided for @bookingHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No previous bookings.'**
  String get bookingHistoryEmpty;

  /// No description provided for @bookingHistoryLoadError.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while loading booking history'**
  String get bookingHistoryLoadError;

  /// No description provided for @reviewBadge.
  ///
  /// In en, this message translates to:
  /// **'Review!'**
  String get reviewBadge;

  /// No description provided for @currencyLYD.
  ///
  /// In en, this message translates to:
  /// **'LYD'**
  String get currencyLYD;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @bookingDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking Details'**
  String get bookingDetailsTitle;

  /// No description provided for @unknownField.
  ///
  /// In en, this message translates to:
  /// **'Unknown field'**
  String get unknownField;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @statusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get statusConfirmed;

  /// No description provided for @bookingCode.
  ///
  /// In en, this message translates to:
  /// **'Booking Code'**
  String get bookingCode;

  /// No description provided for @monthlyDatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking Dates:'**
  String get monthlyDatesTitle;

  /// No description provided for @datesLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load dates'**
  String get datesLoadError;

  /// No description provided for @financialDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Financial Details:'**
  String get financialDetailsTitle;

  /// No description provided for @bookingPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Booking price'**
  String get bookingPriceLabel;

  /// No description provided for @remainingPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Remaining to Pay'**
  String get remainingPriceLabel;

  /// No description provided for @bookingCreatedAt.
  ///
  /// In en, this message translates to:
  /// **'Booking created at:'**
  String get bookingCreatedAt;

  /// No description provided for @cancelNotAllowed24h.
  ///
  /// In en, this message translates to:
  /// **'You cannot cancel within 24 hours of the booking time.'**
  String get cancelNotAllowed24h;

  /// No description provided for @cancelNotAllowed20m.
  ///
  /// In en, this message translates to:
  /// **'You can cancel only after 20 minutes from creation.'**
  String get cancelNotAllowed20m;

  /// No description provided for @cancelConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm cancellation'**
  String get cancelConfirmTitle;

  /// No description provided for @cancelConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this booking?'**
  String get cancelConfirmBody;

  /// No description provided for @cancelBooking.
  ///
  /// In en, this message translates to:
  /// **'Cancel Booking'**
  String get cancelBooking;

  /// No description provided for @cancellingNow.
  ///
  /// In en, this message translates to:
  /// **'Cancelling...'**
  String get cancellingNow;

  /// No description provided for @cancelAvailableAfter.
  ///
  /// In en, this message translates to:
  /// **'Available after'**
  String get cancelAvailableAfter;

  /// No description provided for @leaveReview.
  ///
  /// In en, this message translates to:
  /// **'Leave a Review'**
  String get leaveReview;

  /// No description provided for @closeReview.
  ///
  /// In en, this message translates to:
  /// **'Close Review'**
  String get closeReview;

  /// No description provided for @reviewQuestion.
  ///
  /// In en, this message translates to:
  /// **'How was it?'**
  String get reviewQuestion;

  /// No description provided for @sendReview.
  ///
  /// In en, this message translates to:
  /// **'Submit Review'**
  String get sendReview;

  /// No description provided for @reviewSent.
  ///
  /// In en, this message translates to:
  /// **'Review submitted'**
  String get reviewSent;

  /// No description provided for @reviewSendError.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit review'**
  String get reviewSendError;

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown error occurred'**
  String get unknownError;

  /// No description provided for @connectionError.
  ///
  /// In en, this message translates to:
  /// **'Connection error'**
  String get connectionError;

  /// No description provided for @aboutAppTitle.
  ///
  /// In en, this message translates to:
  /// **'About the App'**
  String get aboutAppTitle;

  /// No description provided for @versionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get versionLabel;

  /// No description provided for @aboutAppDescription.
  ///
  /// In en, this message translates to:
  /// **'An app designed to book sports fields quickly and easily. Browse available fields, check playing times, and complete your booking directly in the app with no hassle.'**
  String get aboutAppDescription;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPasswordTitle;

  /// No description provided for @resetPasswordNewPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get resetPasswordNewPassword;

  /// No description provided for @resetPasswordConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get resetPasswordConfirmPassword;

  /// No description provided for @resetPasswordUpdateButton.
  ///
  /// In en, this message translates to:
  /// **'Update Password'**
  String get resetPasswordUpdateButton;

  /// No description provided for @resetPasswordFillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill all fields'**
  String get resetPasswordFillAllFields;

  /// No description provided for @resetPasswordNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get resetPasswordNotMatch;

  /// No description provided for @resetPasswordSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password updated successfully'**
  String get resetPasswordSuccess;

  /// No description provided for @resetPasswordFail.
  ///
  /// In en, this message translates to:
  /// **'Failed to update password'**
  String get resetPasswordFail;

  /// No description provided for @resetPasswordError.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while updating the password'**
  String get resetPasswordError;

  /// No description provided for @phoneInputTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get phoneInputTitle;

  /// No description provided for @phoneInputSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the phone number registered with us to reset your password:'**
  String get phoneInputSubtitle;

  /// No description provided for @phoneInputLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneInputLabel;

  /// No description provided for @phoneInputContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get phoneInputContinue;

  /// No description provided for @phoneInputEnterPhone.
  ///
  /// In en, this message translates to:
  /// **'Please enter your phone number'**
  String get phoneInputEnterPhone;

  /// No description provided for @phoneInputNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Network connection error'**
  String get phoneInputNetworkError;

  /// No description provided for @phoneInputCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to verify phone number'**
  String get phoneInputCheckFailed;

  /// No description provided for @otpConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get otpConfirm;

  /// No description provided for @otpResend.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get otpResend;

  /// No description provided for @otpInvalidCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid verification code'**
  String get otpInvalidCode;

  /// No description provided for @otpLoginFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to login to SMS service'**
  String get otpLoginFailed;

  /// No description provided for @otpTokenFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to retrieve token'**
  String get otpTokenFailed;

  /// No description provided for @otpSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send verification code'**
  String get otpSendFailed;

  /// No description provided for @otpNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Network error'**
  String get otpNetworkError;

  /// No description provided for @monthlyConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Monthly booking confirmation'**
  String get monthlyConfirmTitle;

  /// No description provided for @monthlyConfirmDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm monthly booking'**
  String get monthlyConfirmDialogTitle;

  /// No description provided for @monthlyConfirmDialogBody.
  ///
  /// In en, this message translates to:
  /// **'Do you want to confirm this booking for 4 sessions?'**
  String get monthlyConfirmDialogBody;

  /// No description provided for @bookingPrice.
  ///
  /// In en, this message translates to:
  /// **'Booking price'**
  String get bookingPrice;

  /// No description provided for @remainingToOwner.
  ///
  /// In en, this message translates to:
  /// **'Remaining to pay the owner'**
  String get remainingToOwner;

  /// No description provided for @confirmMonthlyBookingButton.
  ///
  /// In en, this message translates to:
  /// **'Confirm monthly booking'**
  String get confirmMonthlyBookingButton;

  /// No description provided for @midnightInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Time notice'**
  String get midnightInfoTitle;

  /// No description provided for @midnightInfoBody.
  ///
  /// In en, this message translates to:
  /// **'If the booking extends past midnight (12:00 AM), those hours are actually on the next day, not the selected date.'**
  String get midnightInfoBody;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @notesToOwnerLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes to the owner:'**
  String get notesToOwnerLabel;

  /// No description provided for @monthlyRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Monthly booking request has been sent to the owner.'**
  String get monthlyRequestSent;

  /// No description provided for @bookingConfirmFailed.
  ///
  /// In en, this message translates to:
  /// **'Booking confirmation failed'**
  String get bookingConfirmFailed;

  /// No description provided for @pendingInfoPrefix.
  ///
  /// In en, this message translates to:
  /// **'If your booking stays pending, you can cancel it exactly after 20 minutes.\nYou can’t book another field while a booking is pending.\n\nThe field manager will respond as soon as possible.\n\nThe booking amount '**
  String get pendingInfoPrefix;

  /// No description provided for @pendingInfoMiddle.
  ///
  /// In en, this message translates to:
  /// **' will be deducted once the manager accepts your request, and you will need to pay '**
  String get pendingInfoMiddle;

  /// No description provided for @pendingInfoSuffix.
  ///
  /// In en, this message translates to:
  /// **' to the manager before or after playing.'**
  String get pendingInfoSuffix;

  /// No description provided for @timeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Time notice'**
  String get timeTooltip;

  /// No description provided for @noImages.
  ///
  /// In en, this message translates to:
  /// **'No images'**
  String get noImages;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @fieldTypeFootball.
  ///
  /// In en, this message translates to:
  /// **'Football'**
  String get fieldTypeFootball;

  /// No description provided for @fieldTypeBasketball.
  ///
  /// In en, this message translates to:
  /// **'Basketball'**
  String get fieldTypeBasketball;

  /// No description provided for @fieldTypeTennis.
  ///
  /// In en, this message translates to:
  /// **'Tennis'**
  String get fieldTypeTennis;

  /// No description provided for @fieldTypePadel.
  ///
  /// In en, this message translates to:
  /// **'Padel'**
  String get fieldTypePadel;

  /// No description provided for @fieldTypeUnknown.
  ///
  /// In en, this message translates to:
  /// **''**
  String get fieldTypeUnknown;

  /// No description provided for @locationLabel.
  ///
  /// In en, this message translates to:
  /// **'{city} / {location}'**
  String locationLabel(Object city, Object location);

  /// No description provided for @playersCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Players: {count}'**
  String playersCountLabel(Object count);

  /// No description provided for @fieldTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Field: {type}'**
  String fieldTypeLabel(Object type);

  /// No description provided for @openCloseLabel.
  ///
  /// In en, this message translates to:
  /// **'{open} - {close}'**
  String openCloseLabel(Object close, Object open);

  /// No description provided for @noDescription.
  ///
  /// In en, this message translates to:
  /// **'No description available.'**
  String get noDescription;

  /// No description provided for @favoritesAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add to favorites?'**
  String get favoritesAddTitle;

  /// No description provided for @favoritesRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites?'**
  String get favoritesRemoveTitle;

  /// No description provided for @favoritesAddBody.
  ///
  /// In en, this message translates to:
  /// **'Do you want to add this field to your favorites?'**
  String get favoritesAddBody;

  /// No description provided for @favoritesRemoveBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this field from favorites?'**
  String get favoritesRemoveBody;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @favoritesAdded.
  ///
  /// In en, this message translates to:
  /// **'Added to favorites'**
  String get favoritesAdded;

  /// No description provided for @favoritesRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed from favorites'**
  String get favoritesRemoved;

  /// No description provided for @showSchedule.
  ///
  /// In en, this message translates to:
  /// **'Show schedule'**
  String get showSchedule;

  /// No description provided for @calendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendarTitle;

  /// No description provided for @calendarLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get calendarLoading;

  /// No description provided for @calendarLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load bookings'**
  String get calendarLoadFailed;

  /// No description provided for @slotsChooseTypeTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose booking type'**
  String get slotsChooseTypeTitle;

  /// No description provided for @bookingTypeDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get bookingTypeDaily;

  /// No description provided for @bookingTypeMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get bookingTypeMonthly;

  /// No description provided for @continueBooking.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueBooking;

  /// No description provided for @slotBooked.
  ///
  /// In en, this message translates to:
  /// **'Booked'**
  String get slotBooked;

  /// No description provided for @slotAlreadyBooked.
  ///
  /// In en, this message translates to:
  /// **'This time is already booked'**
  String get slotAlreadyBooked;

  /// No description provided for @slotMustBeConsecutive.
  ///
  /// In en, this message translates to:
  /// **'You must select consecutive slots (max 3 hours)'**
  String get slotMustBeConsecutive;

  /// No description provided for @slotMax3Hours.
  ///
  /// In en, this message translates to:
  /// **'Maximum selection is 3 hours'**
  String get slotMax3Hours;

  /// No description provided for @slotCantRemoveMiddle.
  ///
  /// In en, this message translates to:
  /// **'You can’t remove this slot because it’s in the middle of a consecutive chain'**
  String get slotCantRemoveMiddle;

  /// No description provided for @remainingAfterPlayLabel.
  ///
  /// In en, this message translates to:
  /// **'Remaining to pay'**
  String get remainingAfterPlayLabel;

  /// No description provided for @choosePhoneToContinue.
  ///
  /// In en, this message translates to:
  /// **'Please sign up to continue'**
  String get choosePhoneToContinue;

  /// No description provided for @dailyConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm booking'**
  String get dailyConfirmTitle;

  /// No description provided for @confirmBooking.
  ///
  /// In en, this message translates to:
  /// **'Confirm booking'**
  String get confirmBooking;

  /// No description provided for @confirmBookingQuestion.
  ///
  /// In en, this message translates to:
  /// **'Do you want to confirm this booking?'**
  String get confirmBookingQuestion;

  /// No description provided for @remainingAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Remaining amount'**
  String get remainingAmountLabel;

  /// No description provided for @bookingRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Booking request was sent to the field owner.'**
  String get bookingRequestSent;

  /// No description provided for @midnightTimeWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'Time notice'**
  String get midnightTimeWarningTitle;

  /// No description provided for @midnightTimeWarningBody.
  ///
  /// In en, this message translates to:
  /// **'If the booking extends past midnight (12:00 AM), those hours belong to the next day after the shown date.'**
  String get midnightTimeWarningBody;

  /// No description provided for @notesToOwner.
  ///
  /// In en, this message translates to:
  /// **'Notes to field owner:'**
  String get notesToOwner;

  /// No description provided for @apiErrorMissingUrl.
  ///
  /// In en, this message translates to:
  /// **'Server URL is not configured'**
  String get apiErrorMissingUrl;

  /// No description provided for @apiErrorNoAuth.
  ///
  /// In en, this message translates to:
  /// **'You must be logged in'**
  String get apiErrorNoAuth;

  /// No description provided for @apiErrorConnection.
  ///
  /// In en, this message translates to:
  /// **'Connection error'**
  String get apiErrorConnection;

  /// No description provided for @apiErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get apiErrorGeneric;

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Courto'**
  String get appName;

  /// No description provided for @chargeWalletTitle.
  ///
  /// In en, this message translates to:
  /// **'Charge wallet'**
  String get chargeWalletTitle;

  /// No description provided for @chargeWalletLoginRequired.
  ///
  /// In en, this message translates to:
  /// **'You must log in first'**
  String get chargeWalletLoginRequired;

  /// No description provided for @chargeWalletBankCard.
  ///
  /// In en, this message translates to:
  /// **'Bank card'**
  String get chargeWalletBankCard;

  /// No description provided for @chargeWalletCourtoCard.
  ///
  /// In en, this message translates to:
  /// **'Courto card'**
  String get chargeWalletCourtoCard;

  /// No description provided for @chargeWalletEnterCardNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter card number'**
  String get chargeWalletEnterCardNumber;

  /// No description provided for @chargeWalletCardMustBe13.
  ///
  /// In en, this message translates to:
  /// **'Must be 13 digits'**
  String get chargeWalletCardMustBe13;

  /// No description provided for @chargeWalletDigitsOnly.
  ///
  /// In en, this message translates to:
  /// **'Digits only'**
  String get chargeWalletDigitsOnly;

  /// No description provided for @chargeWalletEnterAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter amount'**
  String get chargeWalletEnterAmount;

  /// No description provided for @chargeWalletAmountRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter the amount'**
  String get chargeWalletAmountRequired;

  /// No description provided for @chargeWalletInvalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Invalid amount'**
  String get chargeWalletInvalidAmount;

  /// No description provided for @chargeWalletMax200.
  ///
  /// In en, this message translates to:
  /// **'Maximum is 200 LYD'**
  String get chargeWalletMax200;

  /// No description provided for @chargeWalletSuccess.
  ///
  /// In en, this message translates to:
  /// **'Wallet charged with {voucherValue} LYD. Current balance: {walletBalance} LYD.'**
  String chargeWalletSuccess(Object voucherValue, Object walletBalance);

  /// No description provided for @chargeWalletGenericError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get chargeWalletGenericError;

  /// No description provided for @pay.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get pay;

  /// No description provided for @statusUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get statusUnavailable;

  /// No description provided for @statusAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get statusAvailable;

  /// No description provided for @supportCategoryBooking.
  ///
  /// In en, this message translates to:
  /// **'Booking'**
  String get supportCategoryBooking;

  /// No description provided for @supportCategoryPaymentWallet.
  ///
  /// In en, this message translates to:
  /// **'Payment / Wallet'**
  String get supportCategoryPaymentWallet;

  /// No description provided for @supportCategoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get supportCategoryOther;

  /// No description provided for @supportIssuePriceMismatch.
  ///
  /// In en, this message translates to:
  /// **'The displayed booking price is different from the paid price'**
  String get supportIssuePriceMismatch;

  /// No description provided for @supportIssueExternalConflict.
  ///
  /// In en, this message translates to:
  /// **'There is an external conflict with my booking'**
  String get supportIssueExternalConflict;

  /// No description provided for @supportIssueCancelDueToCircumstances.
  ///
  /// In en, this message translates to:
  /// **'I want to cancel the booking due to special circumstances'**
  String get supportIssueCancelDueToCircumstances;

  /// No description provided for @supportIssueNoOwnerResponse.
  ///
  /// In en, this message translates to:
  /// **'The field owner is not responding'**
  String get supportIssueNoOwnerResponse;

  /// No description provided for @supportIssueWalletNotChargedDeducted.
  ///
  /// In en, this message translates to:
  /// **'My wallet was not charged even though the amount was deducted'**
  String get supportIssueWalletNotChargedDeducted;

  /// No description provided for @supportIssuePaidMoreThanShown.
  ///
  /// In en, this message translates to:
  /// **'The amount paid is more than the displayed amount'**
  String get supportIssuePaidMoreThanShown;

  /// No description provided for @supportIssueWalletChargedCantBook.
  ///
  /// In en, this message translates to:
  /// **'My wallet is charged but I can’t book'**
  String get supportIssueWalletChargedCantBook;

  /// No description provided for @supportIssueWalletChargeError.
  ///
  /// In en, this message translates to:
  /// **'Error while charging the wallet'**
  String get supportIssueWalletChargeError;

  /// No description provided for @supportIssueRefundMissingOrPartial.
  ///
  /// In en, this message translates to:
  /// **'Refund amount is missing/partial or was not returned to my wallet after canceling my booking'**
  String get supportIssueRefundMissingOrPartial;

  /// No description provided for @supportIssueChangePhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'I want to change the phone number linked to my account'**
  String get supportIssueChangePhoneNumber;

  /// No description provided for @supportIssueAppNotWorkingWell.
  ///
  /// In en, this message translates to:
  /// **'The app is not working properly on my device'**
  String get supportIssueAppNotWorkingWell;

  /// No description provided for @supportIssueNoNotifications.
  ///
  /// In en, this message translates to:
  /// **'I am not receiving notifications'**
  String get supportIssueNoNotifications;

  /// No description provided for @supportIssueDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'I want to delete my account'**
  String get supportIssueDeleteAccount;

  /// No description provided for @supportIssueFieldClosedOnArrival.
  ///
  /// In en, this message translates to:
  /// **'The field was closed when I arrived at the booking time'**
  String get supportIssueFieldClosedOnArrival;

  /// No description provided for @supportIssueFieldBadCondition.
  ///
  /// In en, this message translates to:
  /// **'The field is in bad condition or not like the displayed photos'**
  String get supportIssueFieldBadCondition;

  /// No description provided for @supportIssueNotListed.
  ///
  /// In en, this message translates to:
  /// **'An issue not listed'**
  String get supportIssueNotListed;

  /// No description provided for @paymentPage.
  ///
  /// In en, this message translates to:
  /// **'Charge Wallet'**
  String get paymentPage;

  /// No description provided for @teamsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'This section will open soon'**
  String get teamsComingSoon;

  /// No description provided for @navTeams.
  ///
  /// In en, this message translates to:
  /// **'Teams'**
  String get navTeams;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar': return AppLocalizationsAr();
    case 'en': return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appLanguage => 'App language';

  @override
  String get arabic => 'العربية';

  @override
  String get english => 'English';

  @override
  String get darkMode => 'Dark mode';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get system => 'System';

  @override
  String get fullName => 'Full name';

  @override
  String get phoneNumber => 'Phone number';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get continueText => 'Continue';

  @override
  String get haveAccountLogin => 'Already have an account? Log in';

  @override
  String get signupAgreePrefix => 'By creating an account, you agree to ';

  @override
  String get termsTitle => 'Terms of use';

  @override
  String get close => 'Close';

  @override
  String get signupErrorFillAllFields => 'Please fill in all fields';

  @override
  String get signupErrorArabicFullName => 'Please enter your full name in Arabic';

  @override
  String get signupErrorPasswordRules => 'Password must be 8 to 18 characters and contain letters, with optional numbers or symbols';

  @override
  String get signupErrorPasswordsNotMatch => 'Passwords do not match';

  @override
  String get signupErrorPhoneFormat => 'Please enter a valid phone number starting with 2189';

  @override
  String get termsBody => 'Use of Courto (courto) App – Terms and Conditions\nLast update: 2025-12-13\n\nPlease read these terms carefully before using the Courto (courto) app. By using the app, you fully and unconditionally agree to all terms below.\n\n1. Definitions\n• App: Courto (courto) sports booking app (football, basketball, etc.).\n• User: anyone who downloads the app, creates an account, or uses it to book.\n• Venue owner: the person/entity responsible for the venue listed in the app.\n• Initial booking fee: amount paid via the app to confirm a booking, set by the venue owner and may change before booking.\n• Remaining amount: paid directly to the venue owner on arrival or after play as requested.\n\n2. Booking and payment\n1. User tops up their wallet then selects venue, date, and time.\n2. No amount is deducted until the venue owner accepts.\n3. Once accepted, the initial fee is deducted.\n4. Booking is confirmed after acceptance and successful deduction.\n5. User pays the remaining amount directly to the venue owner.\n6. User is responsible for verifying booking details before submitting.\n7. User cannot create a new booking until the previous pending booking is accepted or rejected.\n\n3. Monthly subscription\n1. Some venues may offer monthly subscription if enabled by the venue owner.\n2. Subscription grants one fixed weekly session for a month (four consecutive weeks).\n3. Payment: initial confirmation fee via the app (based on total hours) and the remaining amount paid directly to the owner at the first session.\nNote: amounts paid via the app are confirmation fees and are refundable only in cases below.\n4. Cancellation/refund follows section (4). User cannot cancel or refund after acceptance or after the first session starts.\n5. No-shows are not eligible for makeup sessions or refunds.\n6. Subscription cannot be transferred/shared without owner approval.\n7. App/owners may modify/stop subscription with prior notice while respecting refunds for non-delivered sessions.\n\n4. Cancellation and refunds\n1. User can cancel only after 20 minutes from creating the booking.\n2. If accepted, user cannot cancel or refund the initial fee.\n3. If user does not attend after acceptance, the initial fee is not refunded.\n4. Owner may cancel for necessity (weather/maintenance); in that case the full initial fee is refunded to the user wallet.\n5. App may suspend/ban users for harmful behavior or repeated disruptive cancellations.\n\n5. User responsibilities\n1. Provide correct data during registration/booking.\n2. Attend on time and follow venue rules.\n3. No transfer/rent of booking without owner approval.\n4. User is responsible for any damages caused.\n\n6. Venue owner responsibilities\n1. Provide the venue at the scheduled time.\n2. Responsible for cancellations/changes after confirmation.\n3. Show pricing clearly without hidden fees.\n\n7. Courto app responsibility\n1. App acts as an electronic intermediary between users and venue owners.\n2. App is not responsible for venue quality/cleanliness/readiness, financial disputes, or injuries/damages during use.\n3. App is not responsible for errors due to incorrect user input.\n4. App may suspend/delete violating accounts.\n\n8. Privacy and data protection\n1. User data is stored securely under the privacy policy.\n2. Data is not shared with third parties except with user consent or legal order.\n3. App may use anonymous statistics to improve services.\n\n9. Intellectual property\nAll content/brands/designs in Courto are owned and legally protected; copying/reuse without permission is prohibited.\n\n10. Changes to terms\nCourto may update these terms anytime; continued use after updates implies acceptance.\n\n11. Governing law and disputes\nThese terms are governed by the laws of Libya; Libyan courts have exclusive jurisdiction.\n\n12. Contact\nFor inquiries/complaints:\ncourtolibya@gmail.com';

  @override
  String get pleaseLogin => 'Please log in';

  @override
  String get phoneNotAvailable => 'No phone number';

  @override
  String get bookingHistory => 'Booking history';

  @override
  String get favoriteFields => 'Favorite fields';

  @override
  String get supportHelp => 'Support & help';

  @override
  String get chargeWallet => 'Charge wallet';

  @override
  String get aboutApp => 'About the app';

  @override
  String get visibilityMode => 'Appearance';

  @override
  String get logout => 'Log out';

  @override
  String get login => 'Log in';

  @override
  String get logoutConfirmTitle => 'Log out?';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get otpTitle => 'Verification Code';

  @override
  String otpSentTo(Object phone) {
    return 'We sent a verification code to $phone';
  }

  @override
  String get confirm => 'Confirm';

  @override
  String get otpResendCode => 'Resend code';

  @override
  String otpResendIn(Object seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String otpSmsMessage(Object code) {
    return 'Your verification code is: $code';
  }

  @override
  String errorPrefix(Object message) {
    return 'Error: $message';
  }

  @override
  String get otpErrorToken => 'Failed to get token';

  @override
  String get otpErrorSendCode => 'Failed to send verification code';

  @override
  String get otpErrorRasaelLogin => 'Failed to login to SMS service';

  @override
  String get otpErrorInvalidCode => 'Incorrect verification code';

  @override
  String get otpAccountCreatedDefault => 'Account created successfully.';

  @override
  String get otpErrorSignupFailed => 'Failed to create account';

  @override
  String get otpErrorDuringSignup => 'An error occurred while creating the account';

  @override
  String get loginErrorFailed => 'Login failed';

  @override
  String get networkError => 'Network error. Please check your internet connection.';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get newUserCreateAccount => 'New user? Create an account';

  @override
  String get landingFeaturedDefault1 => 'Welcome to Courto!';

  @override
  String get landingFeaturedDefault2 => 'Top up • Book • Play';

  @override
  String get tennis => 'Tennis';

  @override
  String get padel => 'Padel';

  @override
  String get offersDiscounts => 'Offers & Discounts';

  @override
  String get matchesPlayed => 'Matches played';

  @override
  String get bookField => 'Book a field';

  @override
  String get createAccount => 'Create account';

  @override
  String get fieldDefaultName => 'Unnamed field';

  @override
  String discountBadge(Object percent) {
    return '$percent% off';
  }

  @override
  String currency(Object value) {
    return 'LYD $value';
  }

  @override
  String get navHome => 'Home';

  @override
  String get navFields => 'Fields';

  @override
  String get navMap => 'Map';

  @override
  String get navSettings => 'Settings';

  @override
  String get errorLoadFields => 'Failed to load fields';

  @override
  String get errorConnection => 'Connection error';

  @override
  String get mapPermissionRequired => 'You must log in and allow location access to view fields on the map.';

  @override
  String get mapNotAvailable => 'The map is currently unavailable. We will try again at the beginning of the month.';

  @override
  String pricePerHour(Object price) {
    return '$price LYD / hour';
  }

  @override
  String get filterCityTitle => 'City';

  @override
  String get filterTypeTitle => 'Field type';

  @override
  String get filterSortTitle => 'Sort by';

  @override
  String get loadingCities => 'Loading cities...';

  @override
  String get sortDistance => 'Distance';

  @override
  String get sortPrice => 'Price';

  @override
  String get filterTooltip => 'Filter';

  @override
  String get typeAll => 'All';

  @override
  String get typeFootball => 'Football';

  @override
  String get typeBasketball => 'Basketball';

  @override
  String get typeTennis => 'Tennis';

  @override
  String get typePadel => 'Padel';

  @override
  String get typePadbol => 'Padbol';

  @override
  String get typeKarting => 'Karting';

  @override
  String get typePaintball => 'Paintball';

  @override
  String get typeGolf => 'Golf';

  @override
  String get typeVolleyball => 'Volleyball';

  @override
  String activeCity(Object city) {
    return 'City: $city';
  }

  @override
  String activeType(Object type) {
    return 'Type: $type';
  }

  @override
  String activeSort(Object sort) {
    return 'Sort: $sort';
  }

  @override
  String kmDistance(Object km) {
    return '$km km';
  }

  @override
  String discountPercent(Object percent) {
    return '-$percent%';
  }

  @override
  String bookingAndPrice(Object booking, Object price) {
    return 'Booking: $booking | $price';
  }

  @override
  String bookingAndPricePerHour(Object booking, Object price) {
    return 'Booking: $booking | $price/hour';
  }

  @override
  String errorWithMessage(Object message) {
    return 'Error: $message';
  }

  @override
  String noFieldsAvailable(Object type, Object city) {
    return 'No $type fields available right now in $city.';
  }

  @override
  String get themeTitle => 'Theme mode';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'System';

  @override
  String get supportTitle => 'Support & Help';

  @override
  String get supportHeaderTitle => 'Contact us to solve your issue';

  @override
  String get supportHeaderDescription => 'Please choose the category and issue and describe it in detail. The support team will contact you via your phone number or WhatsApp as soon as possible.';

  @override
  String get supportCategoryLabel => 'Issue category:';

  @override
  String get supportSelectCategoryHint => 'Select category';

  @override
  String get supportUnknownCategory => 'Unknown category';

  @override
  String get supportIssueLabel => 'Selected issue:';

  @override
  String get supportSelectIssueHint => 'Select issue';

  @override
  String get supportUnknownIssue => 'Unknown issue';

  @override
  String get supportMessageLabel => 'Issue description:';

  @override
  String get supportMessageHint => 'Write issue details here';

  @override
  String get supportSendButton => 'Send support request';

  @override
  String get supportSelectIssueFirst => 'Please select an issue first.';

  @override
  String get supportEnterDescription => 'Please enter the issue description.';

  @override
  String get supportSentSuccess => 'Request sent successfully. We will reply soon.';

  @override
  String get supportErrorNoAuth => 'Error: No authentication token.';

  @override
  String get supportErrorLoadCategories => 'Failed to load categories.';

  @override
  String get supportErrorInternet => 'Could not connect to the server. Check your internet connection.';

  @override
  String get supportErrorServer => 'Could not connect to the server.';

  @override
  String get supportErrorSending => 'An error occurred while sending.';

  @override
  String get policyTitle => 'Terms of Use';

  @override
  String get policyBody => 'Courto (courto) App Terms & Conditions\nLast update: 2025-12-13\nPlease read these terms carefully before using the Courto (courto) app. Your use of the app indicates your full and unconditional acceptance of all the following clauses.\n⸻\n1. Definitions\n• App: The Courto (courto) application for booking sports fields (football, basketball, etc.).\n• User: Any person who downloads the app, creates an account, or uses it to book a field.\n• Field Owner: The person or entity responsible for managing the field listed in the app.\n• Initial Booking Fee: The amount paid via the app to confirm the booking. It is set by the field owner and can be changed before booking.\n• Remaining Amount: The amount paid directly to the field owner on arrival or after playing, depending on the field owner’s policy.\n⸻\n2. Booking & Payment Process\n1. The user tops up their wallet in the app, then selects the field, time, and date for booking.\n2. After sending the request, no funds are deducted until the field owner accepts the booking.\n3. Once accepted, the initial booking fee is deducted from the user’s wallet.\n4. The booking is confirmed after acceptance and successful deduction, and the user receives a confirmation notification.\n5. Upon arriving at the field, the user pays the remaining amount directly to the field owner based on the price shown in the app.\n6. The user is responsible for verifying booking details before submission (time, location, field type).\n7. The user cannot create a new booking until the previous pending booking is accepted or rejected to prevent duplicate requests and ensure fairness.\n⸻\n3. Monthly Subscription\n1. The app offers a monthly subscription option for participating fields, subject to field owner activation.\n2. The subscription gives the user a fixed weekly booking (e.g., Sunday, Monday, etc.) for one month (four consecutive sessions).\n3. Payment:\n• The user pays an initial fee via the app to confirm the subscription, calculated based on the total hours.\n• The remaining amount is paid directly to the field owner at the first session as displayed in the field page.\nNote: Amounts paid via the app are confirmation fees and are refundable only in the cases stated below.\n4. Cancellation & Refund:\n• The same cancellation and refund rules in section (4) apply.\n• The user cannot cancel or refund the initial fee after the subscription is accepted or after the first session begins.\n• The field owner may cancel/adjust sessions for necessary reasons (weather/maintenance). Only the affected session amount is refunded to the user’s wallet.\n5. Attendance:\n• If the user misses any session, they are not entitled to a replacement session or refund.\n6. The subscription cannot be transferred or shared without the field owner’s prior approval.\n7. The app and field owners may modify or stop the subscription service with prior notice while preserving refunds for unfulfilled sessions.\n⸻\n4. Cancellation & Refund\n1. The user can cancel a booking only after 20 minutes of creating it to prevent random cancellations.\n2. If the booking is accepted by the field owner, the user cannot cancel or refund the initial fee.\n3. If the booking is accepted and the user does not attend or changes time, the initial fee is not refunded.\n4. The field owner may cancel in necessary cases (weather/maintenance). In this case, the full initial fee is refunded to the user’s wallet.\n5. The app may suspend/ban any user who harms the system or repeatedly cancels bookings.\n⸻\n5. User Responsibilities\n1. Provide accurate information during registration and booking.\n2. Attend on time and respect field rules.\n3. Do not transfer or rent the booking to another person without field owner approval.\n4. The user is responsible for any damages caused while using the field.\n⸻\n6. Field Owner Responsibilities\n1. Provide the field at the agreed time.\n2. Be responsible for cancellations or changes after confirmation.\n3. Display prices clearly without hidden fees.\n⸻\n7. Courto App Responsibility\n1. The app acts as an electronic intermediary between users and field owners.\n2. The app is not responsible for:\n• Field quality/cleanliness/readiness.\n• Financial disputes between user and field owner.\n• Any physical injury or property damage while using the field.\n3. The app is not responsible for errors caused by incorrect user input.\n4. The app may suspend/delete abusive or violating accounts.\n⸻\n8. Privacy & Data Protection\n1. User data is stored securely under the privacy policy.\n2. Data is not shared with third parties without user consent or legal order.\n3. The app may use anonymous statistical data to improve services.\n⸻\n9. Intellectual Property\nAll content, trademarks, and designs in the Courto app are owned and legally protected. Copying or reuse without permission is prohibited.\n⸻\n10. Changes to Terms\nCourto reserves the right to modify these terms at any time. Continued use after changes indicates acceptance of the updated version.\n⸻\n11. Applicable Law & Disputes\nThese terms are governed by the laws of Libya. Any disputes fall under the jurisdiction of the competent Libyan courts.\n⸻\n12. Contact\nFor inquiries or complaints:\ncourtolibya@gmail.com';

  @override
  String get favoritesTitle => 'Favorites';

  @override
  String get favoritesEmpty => 'No favorite fields';

  @override
  String get favoritesLoadFailed => 'Failed to load favorites';

  @override
  String get favoritesRemoveFailed => 'Failed to remove favorite';

  @override
  String get favoritesRemovedSuccess => 'Removed from favorites';

  @override
  String get confirmDeleteTitle => 'Confirm deletion';

  @override
  String get confirmRemoveFavoriteBody => 'Are you sure you want to remove this field from favorites?';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get cityLabel => 'City';

  @override
  String get capacityLabel => 'Capacity';

  @override
  String get errorConnectionServer => 'Could not connect to the server';

  @override
  String get bookingHistoryTitle => 'Booking History';

  @override
  String get bookingHistoryEmpty => 'No previous bookings.';

  @override
  String get bookingHistoryLoadError => 'An error occurred while loading booking history';

  @override
  String get reviewBadge => 'Review!';

  @override
  String get currencyLYD => 'LYD';

  @override
  String get unknown => 'Unknown';

  @override
  String get bookingDetailsTitle => 'Booking Details';

  @override
  String get unknownField => 'Unknown field';

  @override
  String get statusPending => 'Pending';

  @override
  String get statusConfirmed => 'Confirmed';

  @override
  String get bookingCode => 'Booking Code';

  @override
  String get monthlyDatesTitle => 'Booking Dates:';

  @override
  String get datesLoadError => 'Failed to load dates';

  @override
  String get financialDetailsTitle => 'Financial Details:';

  @override
  String get bookingPriceLabel => 'Booking price';

  @override
  String get remainingPriceLabel => 'Remaining to Pay';

  @override
  String get bookingCreatedAt => 'Booking created at:';

  @override
  String get cancelNotAllowed24h => 'You cannot cancel within 24 hours of the booking time.';

  @override
  String get cancelNotAllowed20m => 'You can cancel only after 20 minutes from creation.';

  @override
  String get cancelConfirmTitle => 'Confirm cancellation';

  @override
  String get cancelConfirmBody => 'Are you sure you want to cancel this booking?';

  @override
  String get cancelBooking => 'Cancel Booking';

  @override
  String get cancellingNow => 'Cancelling...';

  @override
  String get cancelAvailableAfter => 'Available after';

  @override
  String get leaveReview => 'Leave a Review';

  @override
  String get closeReview => 'Close Review';

  @override
  String get reviewQuestion => 'How was it?';

  @override
  String get sendReview => 'Submit Review';

  @override
  String get reviewSent => 'Review submitted';

  @override
  String get reviewSendError => 'Failed to submit review';

  @override
  String get unknownError => 'Unknown error occurred';

  @override
  String get connectionError => 'Connection error';

  @override
  String get aboutAppTitle => 'About the App';

  @override
  String get versionLabel => 'Version';

  @override
  String get aboutAppDescription => 'An app designed to book sports fields quickly and easily. Browse available fields, check playing times, and complete your booking directly in the app with no hassle.';

  @override
  String get resetPasswordTitle => 'Reset Password';

  @override
  String get resetPasswordNewPassword => 'New Password';

  @override
  String get resetPasswordConfirmPassword => 'Confirm New Password';

  @override
  String get resetPasswordUpdateButton => 'Update Password';

  @override
  String get resetPasswordFillAllFields => 'Please fill all fields';

  @override
  String get resetPasswordNotMatch => 'Passwords do not match';

  @override
  String get resetPasswordSuccess => 'Password updated successfully';

  @override
  String get resetPasswordFail => 'Failed to update password';

  @override
  String get resetPasswordError => 'An error occurred while updating the password';

  @override
  String get phoneInputTitle => 'Reset Password';

  @override
  String get phoneInputSubtitle => 'Enter the phone number registered with us to reset your password:';

  @override
  String get phoneInputLabel => 'Phone number';

  @override
  String get phoneInputContinue => 'Continue';

  @override
  String get phoneInputEnterPhone => 'Please enter your phone number';

  @override
  String get phoneInputNetworkError => 'Network connection error';

  @override
  String get phoneInputCheckFailed => 'Failed to verify phone number';

  @override
  String get otpConfirm => 'Confirm';

  @override
  String get otpResend => 'Resend code';

  @override
  String get otpInvalidCode => 'Invalid verification code';

  @override
  String get otpLoginFailed => 'Failed to login to SMS service';

  @override
  String get otpTokenFailed => 'Failed to retrieve token';

  @override
  String get otpSendFailed => 'Failed to send verification code';

  @override
  String get otpNetworkError => 'Network error';

  @override
  String get monthlyConfirmTitle => 'Monthly booking confirmation';

  @override
  String get monthlyConfirmDialogTitle => 'Confirm monthly booking';

  @override
  String get monthlyConfirmDialogBody => 'Do you want to confirm this booking for 4 sessions?';

  @override
  String get bookingPrice => 'Booking price';

  @override
  String get remainingToOwner => 'Remaining to pay the owner';

  @override
  String get confirmMonthlyBookingButton => 'Confirm monthly booking';

  @override
  String get midnightInfoTitle => 'Time notice';

  @override
  String get midnightInfoBody => 'If the booking extends past midnight (12:00 AM), those hours are actually on the next day, not the selected date.';

  @override
  String get ok => 'OK';

  @override
  String get notesToOwnerLabel => 'Notes to the owner:';

  @override
  String get monthlyRequestSent => 'Monthly booking request has been sent to the owner.';

  @override
  String get bookingConfirmFailed => 'Booking confirmation failed';

  @override
  String get pendingInfoPrefix => 'If your booking stays pending, you can cancel it exactly after 20 minutes.\nYou can book up to 3 fields at once, and in case a booking is accepted, all other pending booking on that day are automatically cancelled.\n\nThe field manager will respond as soon as possible.\n\nThe booking amount ';

  @override
  String get pendingInfoMiddle => ' will be deducted once the manager accepts your request, and you will need to pay ';

  @override
  String get pendingInfoSuffix => ' to the manager before or after playing. \n The booking can be cancelled only 24 hours before it\'s date.';

  @override
  String get timeTooltip => 'Time notice';

  @override
  String get noImages => 'No images';

  @override
  String get loading => 'Loading...';

  @override
  String get fieldTypeFootball => 'Football';

  @override
  String get fieldTypeBasketball => 'Basketball';

  @override
  String get fieldTypeTennis => 'Tennis';

  @override
  String get fieldTypePadel => 'Padel';

  @override
  String get fieldTypeUnknown => '';

  @override
  String locationLabel(Object city, Object location) {
    return '$city / $location';
  }

  @override
  String playersCountLabel(Object count) {
    return 'Players: $count';
  }

  @override
  String fieldTypeLabel(Object type) {
    return 'Field: $type';
  }

  @override
  String openCloseLabel(Object close, Object open) {
    return '$open - $close';
  }

  @override
  String get noDescription => 'No description available.';

  @override
  String get favoritesAddTitle => 'Add to favorites?';

  @override
  String get favoritesRemoveTitle => 'Remove from favorites?';

  @override
  String get favoritesAddBody => 'Do you want to add this field to your favorites?';

  @override
  String get favoritesRemoveBody => 'Are you sure you want to remove this field from favorites?';

  @override
  String get add => 'Add';

  @override
  String get remove => 'Remove';

  @override
  String get favoritesAdded => 'Added to favorites';

  @override
  String get favoritesRemoved => 'Removed from favorites';

  @override
  String get showSchedule => 'Show schedule';

  @override
  String get calendarTitle => 'Calendar';

  @override
  String get calendarLoading => 'Loading...';

  @override
  String get calendarLoadFailed => 'Failed to load bookings';

  @override
  String get slotsChooseTypeTitle => 'Choose booking type';

  @override
  String get bookingTypeDaily => 'Daily';

  @override
  String get bookingTypeMonthly => 'Monthly';

  @override
  String get continueBooking => 'Continue';

  @override
  String get slotBooked => 'Booked';

  @override
  String get slotAlreadyBooked => 'This time is already booked';

  @override
  String get slotMustBeConsecutive => 'You must select consecutive slots (max 3 hours)';

  @override
  String get slotMax3Hours => 'Maximum selection is 3 hours';

  @override
  String get slotCantRemoveMiddle => 'You can’t remove this slot because it’s in the middle of a consecutive chain';

  @override
  String get remainingAfterPlayLabel => 'Remaining to pay';

  @override
  String get choosePhoneToContinue => 'Please sign up to continue';

  @override
  String get dailyConfirmTitle => 'Confirm booking';

  @override
  String get confirmBooking => 'Confirm booking';

  @override
  String get confirmBookingQuestion => 'Do you want to confirm this booking?';

  @override
  String get remainingAmountLabel => 'Remaining amount';

  @override
  String get bookingRequestSent => 'Booking request was sent to the field owner.';

  @override
  String get midnightTimeWarningTitle => 'Time notice';

  @override
  String get midnightTimeWarningBody => 'If the booking extends past midnight (12:00 AM), those hours belong to the next day after the shown date.';

  @override
  String get notesToOwner => 'Notes to field owner:';

  @override
  String get apiErrorMissingUrl => 'Server URL is not configured';

  @override
  String get apiErrorNoAuth => 'You must be logged in';

  @override
  String get apiErrorConnection => 'Connection error';

  @override
  String get apiErrorGeneric => 'Something went wrong';

  @override
  String get appName => 'Courto';

  @override
  String get chargeWalletTitle => 'Charge wallet';

  @override
  String get chargeWalletLoginRequired => 'You must log in first';

  @override
  String get chargeWalletBankCard => 'Bank card';

  @override
  String get chargeWalletCourtoCard => 'Courto card';

  @override
  String get chargeWalletEnterCardNumber => 'Enter card number';

  @override
  String get chargeWalletCardMustBe13 => 'Must be 13 digits';

  @override
  String get chargeWalletDigitsOnly => 'Digits only';

  @override
  String get chargeWalletEnterAmount => 'Enter amount';

  @override
  String get chargeWalletAmountRequired => 'Please enter the amount';

  @override
  String get chargeWalletInvalidAmount => 'Invalid amount';

  @override
  String get chargeWalletMax => 'Maximum is 1000 LYD';

  @override
  String chargeWalletSuccess(Object voucherValue, Object walletBalance) {
    return 'Wallet charged with $voucherValue LYD. Current balance: $walletBalance LYD.';
  }

  @override
  String get chargeWalletGenericError => 'Something went wrong';

  @override
  String get pay => 'Pay';

  @override
  String get statusUnavailable => 'Unavailable';

  @override
  String get statusAvailable => 'Available';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get supportCategoryBooking => 'Booking';

  @override
  String get supportCategoryPaymentWallet => 'Payment / Wallet';

  @override
  String get supportCategoryOther => 'Other';

  @override
  String get supportIssuePriceMismatch => 'The displayed booking price is different from the paid price';

  @override
  String get supportIssueExternalConflict => 'There is an external conflict with my booking';

  @override
  String get supportIssueCancelDueToCircumstances => 'I want to cancel the booking due to special circumstances';

  @override
  String get supportIssueNoOwnerResponse => 'The field owner is not responding';

  @override
  String get supportIssueWalletNotChargedDeducted => 'My wallet was not charged even though the amount was deducted';

  @override
  String get supportIssuePaidMoreThanShown => 'The amount paid is more than the displayed amount';

  @override
  String get supportIssueWalletChargedCantBook => 'My wallet is charged but I can’t book';

  @override
  String get supportIssueWalletChargeError => 'Error while charging the wallet';

  @override
  String get supportIssueRefundMissingOrPartial => 'Refund amount is missing/partial or was not returned to my wallet after canceling my booking';

  @override
  String get supportIssueChangePhoneNumber => 'I want to change the phone number linked to my account';

  @override
  String get supportIssueAppNotWorkingWell => 'The app is not working properly on my device';

  @override
  String get supportIssueNoNotifications => 'I am not receiving notifications';

  @override
  String get supportIssueDeleteAccount => 'I want to delete my account';

  @override
  String get supportIssueFieldClosedOnArrival => 'The field was closed when I arrived at the booking time';

  @override
  String get supportIssueFieldBadCondition => 'The field is in bad condition or not like the displayed photos';

  @override
  String get supportIssueNotListed => 'An issue not listed';

  @override
  String get paymentPage => 'Charge Wallet';

  @override
  String get teamsComingSoon => 'This section will open soon';

  @override
  String get navTeams => 'Teams';

  @override
  String get createMatch => 'Create match';

  @override
  String get noMatchesNow => 'No matches available right now';

  @override
  String get sectionMyMatch => 'Your match';

  @override
  String get sectionJoinedMatches => 'Matches you joined';

  @override
  String get sectionBrowseMatches => 'Browse matches';

  @override
  String get badgeJoined => 'Joined';

  @override
  String get matchStatusOpen => 'Open';

  @override
  String get matchStatusActive => 'Active';

  @override
  String get matchStatusClosed => 'Closed';

  @override
  String get userFallback => 'User';

  @override
  String get fieldFallback => 'Field';

  @override
  String get errorLoadMatches => 'Failed to load matches';

  @override
  String playersCount(int joined, int total) {
    return 'Players: $joined/$total';
  }

  @override
  String get createMatchTitle => 'Create Match';

  @override
  String get createMatchSelectBookingTitle => 'Choose a booking to create a match:';

  @override
  String get createMatchNoEligibleBookings => 'Please book a field to create a match and find players.';

  @override
  String get createMatchOpenSlotsQuestion => 'How many open slots in the match?';

  @override
  String createMatchAvailableToJoin(int openSlots, int capacity) {
    return 'Available to join: $openSlots / $capacity';
  }

  @override
  String createMatchCapacityLabel(int capacity) {
    return 'Capacity: $capacity';
  }

  @override
  String get createMatchChooseYourPositionBlue => 'Choose your position (Blue team)';

  @override
  String createMatchSelectedPosition(String position) {
    return 'Selected position: $position';
  }

  @override
  String get createMatchNoCapacityFormation => 'No capacity available to show formation';

  @override
  String get createMatchNoCapacityPositions => 'No capacity to show positions';

  @override
  String get createMatchNoPositions => 'No positions';

  @override
  String get createMatchCreating => 'Creating...';

  @override
  String get createMatchButton => 'Create match';

  @override
  String get createMatchLoginRequired => 'You must log in first';

  @override
  String get createMatchLoadEligibleBookingsFailed => 'Failed to load eligible bookings';

  @override
  String get createMatchConnectionError => 'Connection error';

  @override
  String get createMatchBookingIdMissing => 'Error: booking_id is missing';

  @override
  String get createMatchPickValidPositionFirst => 'Please pick a valid position first';

  @override
  String get createMatchCreatedSuccess => 'Match created successfully';

  @override
  String get createMatchCreateFailed => 'Failed to create match';

  @override
  String get fieldTypeSport => 'Sport';

  @override
  String get commonUser => 'User';

  @override
  String get commonConnectionError => 'Connection error';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonBack => 'Back';

  @override
  String get matchDetailsTitle => 'Match Details';

  @override
  String get matchDetailsLoadFailed => 'Could not load match details';

  @override
  String get matchDetailsFieldFallback => 'Field';

  @override
  String get matchDetailsJoinRequestSent => 'Join request sent';

  @override
  String get matchDetailsJoinRequestFailed => 'Could not send request';

  @override
  String get matchDetailsJoinRequestTitle => 'Join Request';

  @override
  String get matchDetailsTeamBlue => 'Blue';

  @override
  String get matchDetailsTeamRed => 'Red';

  @override
  String get matchDetailsSendRequest => 'Send request';

  @override
  String matchDetailsJoinRequestConfirm(String team, int position) {
    return 'Do you want to request this slot?\n\nTeam: $team\nPosition: $position';
  }

  @override
  String get matchDetailsRequestAccepted => 'Request accepted';

  @override
  String get matchDetailsAcceptFailed => 'Could not accept request';

  @override
  String get matchDetailsRequestRejected => 'Request rejected';

  @override
  String get matchDetailsRejectFailed => 'Could not reject request';

  @override
  String matchDetailsSlotRequestsTitle(int position, String team) {
    return 'Slot $position requests • $team';
  }

  @override
  String get matchDetailsNoRequestsForSlot => 'No requests for this slot';

  @override
  String get matchDetailsAccept => 'Accept';

  @override
  String get matchDetailsReject => 'Reject';

  @override
  String get matchDetailsCanceled => 'Match canceled';

  @override
  String get matchDetailsCancelFailed => 'Could not cancel match';

  @override
  String get matchDetailsCancelTitle => 'Cancel Match';

  @override
  String get matchDetailsCancelConfirm => 'Are you sure you want to cancel this match?';

  @override
  String get matchDetailsCancelButton => 'Cancel match';

  @override
  String get matchDetailsNoCapacityFormation => 'No capacity to display formation';

  @override
  String get matchDetailsJoinSlotsFull => 'All available join slots are filled';

  @override
  String matchDetailsRemainingSlots(int count) {
    return 'Remaining slots: $count';
  }

  @override
  String get matchDetailsYouAreHost => 'You are the host';

  @override
  String get matchDetailsYouJoined => 'You joined this match';

  @override
  String get matchDetailsPendingReview => 'Your request is under review';

  @override
  String get matchDetailsBlueFormation => 'Blue Team Formation';

  @override
  String get matchDetailsRedFormation => 'Red Team Formation';

  @override
  String get blueTeam => 'Blue Team';

  @override
  String get redTeam => 'Red Team';

  @override
  String get matchDetailsLeaveTitle => 'Leave match';

  @override
  String get matchDetailsLeaveConfirm => 'Are you sure you want to leave this match?';

  @override
  String get matchDetailsLeaveButton => 'Leave match';

  @override
  String get matchDetailsLeftMatch => 'You left the match';

  @override
  String get matchDetailsLeaveFailed => 'Failed to leave the match';

  @override
  String get cancelReasonTitle => 'Reason for cancellation';

  @override
  String get subscriptionsPage => 'My Subscriptions';
}

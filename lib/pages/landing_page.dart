import 'package:carousel_slider/carousel_slider.dart';
import 'package:courto/pages/bookingsPages/field_details_page.dart';
import 'package:courto/pages/login_page.dart';
import 'package:courto/pages/signup_page.dart';
import 'package:courto/pages/subscription_plan_page.dart';
import 'package:courto/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:courto/constants.dart'; // ✅ use your real AppFormat (supports locale)

// --- Global Design Constants for a cleaner look ---
const double kPadding = 16.0;

class LandingPage extends StatelessWidget {
  final List<String> carouselImages;
  final bool hasUpcomingBooking;
  final List<Map<String, dynamic>> discountedFields;
  final String? featuredText1;
  final String? featuredText2;
  final onGoToFieldsPage;
  final int matchesPlayedCount;
  final List<Map<String, dynamic>> subscriptionPlans;

  LandingPage({
    super.key,
    required this.carouselImages,
    required this.hasUpcomingBooking,
    required this.discountedFields,
    required this.featuredText1,
    required this.featuredText2,
    required this.onGoToFieldsPage,
    required this.matchesPlayedCount,
    required this.subscriptionPlans,
  });

  final String? _apiUrl = dotenv.env['API_URL'];

  static const Map<String, String> _cityNameEn = {
    "طرابلس": "Tripoli",
    "مصراتة": "Misrata",
    "بنغازي": "Benghazi",
    "الزاوية": "Zawiya",
    "الخمس":"Khoms",
    "سرت":"Surt",
    "درنة":"Derna",
    "طبرق":"Tobruk",
    "سبها":"Sabha",
    "صبراتة": "Subrata",
    "زوارة":"Zuwara"
  };


    static const Map<String, String> _locationEnMap = {
    "الظهرة": "Al Dahra",
    "زاوية الدهماني": "Zawiyat Al Dahmani",
    "أبو سليم": "Abu Salim",
    "الحي الإسلامي": "Al Islamic District",
    "الدريبي": "Al Draybi",
    "السراج": "Al Sarraj",
    "المدينة القديمة": "Old City",
    "الهاني": "Al Hani",
    "الهضبة الخضراء": "Green Plateau",
    "باب بن غشير": "Bab Ben Ghashir",
    "حي الأندلس": "Hay Al Andalus",
    "حي دمشق": "Hay Dimashq",
    "رأس حسن": "Ras Hassan",
    "زناتة": "Zanata", 
    "سوق الجمعة": "Souq Al Jomaa",
    "غوط الشعال": "Ghout Al Shaal",
    "المنصورة": "Al Mansoura",
    "وسعاية أبديري": "Wesaaeya Abdeeri",
    "الصريم": "Al Srim",
    "بن عاشور": "Bin Ashour",
    "جنزور": "Janzour",
    "تاجوراء": "Tajoura",
    "المدينة": "Al Madina"

  };
  String _locationLabel(String location, bool isEnglish) {
  if (!isEnglish) return location;
  return _locationEnMap[location.trim()] ?? location;
}


  String _cityLabel(String city, bool isEnglish) {
    if (!isEnglish) return city;
    return _cityNameEn[city] ?? city;
  }

  String getFirstImageUrl(List<dynamic> images) {
    if (images.isEmpty) return "";
    final url = images[0]?.toString() ?? "";
    if (url.isEmpty || url.startsWith("http")) return url;

    final baseUrl = _apiUrl;
    try {
      return Uri.parse(baseUrl!).resolve(url).toString();
    } catch (e) {
      return baseUrl!.endsWith('/') ? '$baseUrl$url' : '$baseUrl/$url';
    }
  }

  static const Map<String, String> _planTypeImage = {
    'chess':    'assets/images/courtoChess.png',
    'academy':  'assets/images/courtoTeams.jpg',
    'swimming': 'assets/images/courtoSwimming.png',
    'fitness':  'assets/images/courtoFitness.png',
    'arcade': 'assets/images/courtoArcade.png'
  };

static const Map<String, IconData> _planTypeIcon = {
  'chess':    Icons.grid_on_rounded,
  'academy':  Icons.directions_run,
  'swimming': Icons.pool,
  'fitness':  Icons.fitness_center,
  'arcade': Icons.gamepad_outlined
};

Widget _buildSignUpSections(BuildContext context, bool isEnglish) {
  if (subscriptionPlans.isEmpty) return const SizedBox.shrink();

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: kPadding),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < subscriptionPlans.length; i++) ...[
          _buildPlanCard(context, isEnglish, subscriptionPlans[i], i),
          if (i < subscriptionPlans.length - 1) const SizedBox(height: 16),
        ],
      ],
    ),
  );
}

Widget _buildPlanCard(BuildContext context, bool isEnglish, Map<String, dynamic> plan, int planIndex) {
  final type      = (plan['type'] ?? '').toString().toLowerCase();
  final imagePath = _planTypeImage[type] ?? 'assets/images/courtoDefaultHeader.jpg';
  final icon      = _planTypeIcon[type] ?? Icons.star_outline;

  final title       = isEnglish ? (plan['name_eng'] ?? plan['name'] ?? '') : (plan['name'] ?? '');
  final description = isEnglish ? (plan['short_description_eng'] ?? plan['short_description'] ?? '') : (plan['short_description'] ?? '');
  final buttonLabel = isEnglish ? 'Subscribe' : 'اشترك الآن';

  return _buildProgramCard(
    context:     context,
    isEnglish:   isEnglish,
    imagePath:   imagePath,
    title:       title.toString(),
    description: description.toString(),
    buttonLabel: buttonLabel,
    icon:        icon,
    onTap: () {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => SubscriptionPlanPage(plans: subscriptionPlans, initialIndex: planIndex,),
      ));
    },
  );
}

  String normalizeUrl(String url) {
    if (url.startsWith("http")) {
      final uri = Uri.parse(url);
      final normalizedPath = uri.path.replaceAll(RegExp(r'/{2,}'), '/');
      return "${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}$normalizedPath";
    }

    final base =
        _apiUrl?.endsWith('/') == true ? _apiUrl!.substring(0, _apiUrl.length - 1) : _apiUrl ?? '';
    final path = url.startsWith('/') ? url : '/$url';
    return "$base$path".replaceAll(RegExp(r'/{2,}'), '/');
  }

  Icon _getFieldTypeIcon(String? type) {
    switch (type) {
      case "tennis":
        return const Icon(Icons.sports_baseball, color: Colors.white, size: 22);

      case "football":
      case "padbol":
        return const Icon(Icons.sports_soccer, color: Colors.white, size: 22);

      case "basketball":
        return const Icon(Icons.sports_basketball, color: Colors.white, size: 22);

      case "volleyball":
        return const Icon(Icons.sports_volleyball, color: Colors.white, size: 22);

      case "padel":
        return const Icon(Icons.sports_tennis, color: Colors.white, size: 22);

      case "paintball":
        return const Icon(Icons.format_paint_rounded, color: Colors.white, size: 22);

      case "carting":
        return const Icon(Icons.airline_seat_recline_extra_rounded, color: Colors.white, size: 22);

      case "golf":
        return const Icon(Icons.golf_course, color: Colors.white, size: 22);

      default:
        return const Icon(Icons.sports, color: Colors.white, size: 22);
    }
  }

  Widget _buildSportCategoryButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required int categoryIndex,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () => onGoToFieldsPage(categoryIndex),
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(10),
          color: Theme.of(context).colorScheme.primary,
          child: Container(
            height: 80,
            padding: const EdgeInsets.all(4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 30),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDiscountedFieldCard(Map<String, dynamic> field, BuildContext context, bool isEnglish) {
    final imageUrl = getFirstImageUrl(field["field_images"] ?? []);

    // ✅ English name support
    final fieldName = isEnglish
        ? (field["field_english_name"] ?? field["field_name"] ?? "Field")
        : (field["field_name"] ?? "ملعب");

    final cityRaw = field["field_city"] ?? "";
    final city = _cityLabel(cityRaw.toString(), isEnglish);

    final locationRaw = (field["field_location"] ?? "").toString();
    final location = _locationLabel(locationRaw, isEnglish);

    final capacity = field["field_capacity"]?.toString() ?? "";
    final openTime = field["field_open_time"] ?? "";
    final closeTime = field["field_close_time"] ?? "";
    final fieldType = field["field_type"] ?? "";

    final originalPrice =
        double.tryParse(field["field_calculated_total_price"]?.toString() ?? "0") ?? 0;
    final discountPrice =
        double.tryParse(field["field_calculated_total_price_after_discount"]?.toString() ?? "0") ?? 0;

    final hasDiscount = field["field_has_discount"] == true;

    int discountPercent = 0;
    if (hasDiscount && originalPrice > 0 && discountPrice > 0) {
      discountPercent = (100 - (discountPrice / originalPrice * 100)).round();
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => FieldDetailsPage(field: field)));
      },
      child: Container(
        width: 250,
        height: 240,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  child: Image.network(
                    imageUrl,
                    width: 250,
                    height: 130,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 130,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image_not_supported, color: Colors.grey),
                    ),
                  ),
                ),

                // ✅ discount badge
                if (hasDiscount)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isEnglish ? "$discountPercent% OFF" : "خصم $discountPercent%",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: _getFieldTypeIcon(fieldType),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fieldName.toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          "$city - $location",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSecondary),
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.people, size: 14, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            capacity,
                            style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            isEnglish
                                ? "LYD ${discountPrice.toStringAsFixed(1)}"
                                : "د.ل ${discountPrice.toStringAsFixed(1)}",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isEnglish
                                ? "LYD ${originalPrice.toStringAsFixed(1)}"
                                : "د.ل ${originalPrice.toStringAsFixed(1)}",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        "${AppFormat.formatArabicTime(openTime)} - ${AppFormat.formatArabicTime(closeTime)}",
                        style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSecondary),
                        textDirection: isEnglish ? ui.TextDirection.ltr : ui.TextDirection.rtl,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEnglish = Localizations.localeOf(context).languageCode == "en";

    return Directionality(
      textDirection: isEnglish ? ui.TextDirection.ltr : ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              Stack(
                children: [
                  CarouselSlider(
                    options: CarouselOptions(
                      height: 220,
                      viewportFraction: 1,
                      autoPlay: true,
                      autoPlayInterval: const Duration(seconds: 4),
                      autoPlayCurve: Curves.easeIn,
                      enableInfiniteScroll: true,
                    ),
                    items: (carouselImages.isNotEmpty
                            ? carouselImages
                            : ["assets/images/courtoDefaultHeader.jpg"])
                        .map((img) {
                      final imageUrl = normalizeUrl(img);
                      return ClipRRect(
                        child: imageUrl.startsWith('http')
                            ? Image.network(
                                imageUrl,
                                width: double.infinity,
                                height: 240,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Image.asset(
                                  "assets/images/courtoDefaultHeader.jpg",
                                  width: double.infinity,
                                  height: 240,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Image.asset(
                                imageUrl,
                                width: double.infinity,
                                height: 240,
                                fit: BoxFit.cover,
                              ),
                      );
                    }).toList(),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.center,
                          colors: [
                            Colors.black.withOpacity(0.6),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: kPadding),
                child: SizedBox(
                  width: double.infinity,
                  child: _ctaButtons(context, isEnglish),
                ),
              ),

              const SizedBox(height: 30),

              _FeaturedTextMarquee(
                isEnglish: isEnglish,
                text1: (featuredText1 == null || featuredText1!.isEmpty)
                    ? (isEnglish ? "Welcome to Courto!" : "مرحبا بكم في كورتو!")
                    : featuredText1!,
                text2: (featuredText2 == null || featuredText2!.isEmpty)
                    ? (isEnglish ? "Top up • Book • Play" : "اشحن احجز العب")
                    : featuredText2!,
              ),

              const SizedBox(height: 30),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: kPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SingleChildScrollView(
                      child: Row(
                        children: [
                          _buildSportCategoryButton(
                            context: context,
                            label: isEnglish ? "Tennis" : "تنس",
                            icon: Icons.sports_baseball,
                            categoryIndex: 3,
                          ),
                          const SizedBox(width: kPadding / 2),
                          _buildSportCategoryButton(
                            context: context,
                            label: isEnglish ? "Padel" : "بادل",
                            icon: Icons.sports_tennis_sharp,
                            categoryIndex: 4,
                          ),
                                                    const SizedBox(width: kPadding / 2),

                                                    _buildSportCategoryButton(
                            context: context,
                            label: isEnglish ? "Football" : "كرة القدم",
                            icon: Icons.sports_soccer,
                            categoryIndex: 1,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

_buildSignUpSections(context, isEnglish),

const SizedBox(height: 30),

              if (discountedFields.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: kPadding),
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      isEnglish ? "Offers & Discounts" : "العروض و التخفيضات",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 10),
              SizedBox(
                height: 240,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: kPadding, vertical: 8),
                  itemCount: discountedFields.length,
                  itemBuilder: (context, index) {
                    return _buildDiscountedFieldCard(discountedFields[index], context, isEnglish);
                  },
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ctaButtons(BuildContext context, bool isEnglish) {
    if (AuthService.isLoggedIn) {
      return _loggedInButtons(context, isEnglish);
    } else {
      return _loginSignupButtons(context, isEnglish);
    }
  }

  Widget _loginSignupButtons(BuildContext context, bool isEnglish) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage()));
            },
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(5),
              color: Theme.of(context).colorScheme.primary,
              child: Container(
                height: 120,
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.login, color: Colors.white, size: 40),
                    const SizedBox(height: 8),
                    Text(
                      isEnglish ? "Log in" : "تسجيل الدخول",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: kPadding),
        Expanded(
          child: GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupPage()));
            },
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(5),
              color: Theme.of(context).colorScheme.primary,
              child: Container(
                height: 120,
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.person_add, color: Colors.white, size: 40),
                    const SizedBox(height: 8),
                    Text(
                      isEnglish ? "Sign up" : "إنشاء حساب",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _loggedInButtons(BuildContext context, bool isEnglish) {
    const double buttonHeight = 120.0;

    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, "/bookingHistoryPage");
                },
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(5),
                  color: Theme.of(context).colorScheme.primary,
                  child: Container(
                    height: (buttonHeight - 4) / 2,
                    width: double.infinity,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.history, color: Colors.white, size: 24),
                        const SizedBox(height: 4),
                        Text(
                          isEnglish ? "Booking history" : "سجل الحجوزات",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(5),
                color: Theme.of(context).colorScheme.primary,
                child: Container(
                  height: (buttonHeight - 4) / 2,
                  width: double.infinity,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "$matchesPlayedCount",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        isEnglish ? "Matches played" : "مباريات لعبت",
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: kPadding),
        Expanded(
          child: GestureDetector(
            onTap: () {
              onGoToFieldsPage(1);
            },
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(5),
              color: Theme.of(context).colorScheme.primary,
              child: Container(
                height: buttonHeight,
                width: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.stadium, color: Colors.white, size: 45),
                    const SizedBox(height: 8),
                    Text(
                      isEnglish ? "Book a field" : "احجز ملعب",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}


Widget _buildProgramCard({
  required BuildContext context,
  required bool isEnglish,
  required String imagePath,
  required String title,
  required String description,
  required String buttonLabel,
  required IconData icon,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [

          // --- Background image ---
          Positioned.fill(
            child: Image.asset(
              imagePath,
              fit: BoxFit.cover,
              // smooth fade-in as the image loads
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                if (wasSynchronouslyLoaded) return child;
                return AnimatedOpacity(
                  opacity: frame == null ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeIn,
                  child: child,
                );
              },
              errorBuilder: (_, __, ___) => Container(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
              ),
            ),
          ),

          // --- Dark gradient overlay so text is always readable ---
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.35),
                    Colors.black.withOpacity(0.75),
                  ],
                ),
              ),
            ),
          ),

          // --- Card content ---
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Icon + Title row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Icon(icon, color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black45,
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Description
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.9),
                    height: 1.55,
                    shadows: const [
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // CTA button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      elevation: 0,
                    ),
                    child: Text(
                      buttonLabel,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

        ],
      ),
    ),
  );
}


class _FeaturedTextMarquee extends StatefulWidget {
  final String text1;
  final String text2;
  final bool isEnglish;

  const _FeaturedTextMarquee({
    required this.text1,
    required this.text2,
    required this.isEnglish,
  });

  @override
  _FeaturedTextMarqueeState createState() => _FeaturedTextMarqueeState();
}

class _FeaturedTextMarqueeState extends State<_FeaturedTextMarquee> {
  final ScrollController _scrollController = ScrollController();
  static const Duration scrollDuration = Duration(seconds: 40);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startScrolling();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _startScrolling() {
    if (!_scrollController.hasClients) return;

    final double maxScroll = _scrollController.position.maxScrollExtent;

    if (maxScroll > 0) {
      _scrollController
          .animateTo(
        maxScroll,
        duration: scrollDuration,
        curve: Curves.linear,
      )
          .then((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0.0);
        }
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted) _startScrolling();
        });
      });
    } else {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _startScrolling();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: widget.isEnglish ? ui.TextDirection.ltr : ui.TextDirection.rtl,
      child: Container(
        height: 40,
        width: double.infinity,
        color: Theme.of(context).colorScheme.primary,
        child: ShaderMask(
          shaderCallback: (Rect bounds) {
            return const LinearGradient(
              colors: [Colors.white, Colors.transparent, Colors.transparent, Colors.white],
              stops: [0.0, 0.05, 0.95, 1.0],
              tileMode: TileMode.clamp,
            ).createShader(bounds);
          },
          blendMode: BlendMode.dstOut,
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: kPadding),
              child: Row(
                children: [
                  _text(widget.text1, Colors.amber),
                  _text(widget.text2, Colors.white),
                  _text(widget.text1, Colors.amber),
                  _text(widget.text2, Colors.white),
                  _text(widget.text1, Colors.amber),
                  _text(widget.text2, Colors.white),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _text(String text, Color color) {
    return Text(
      "$text  |  ",
      style: TextStyle(
        color: color,
        fontSize: 18,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

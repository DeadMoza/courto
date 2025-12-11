import 'package:carousel_slider/carousel_slider.dart';
import 'package:courto/pages/bookingsPages/field_details_page.dart';
import 'package:courto/pages/login_page.dart';
import 'package:courto/pages/signup_page.dart';
import 'package:courto/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter_dotenv/flutter_dotenv.dart';

// --- Global Design Constants for a cleaner look ---
const Color kPrimaryColor = Colors.redAccent;
const Color kBackgroundColor = Color(0xFFFAFAFA); // Very light grey background
const double kPadding = 16.0;

// Placeholder for AppFormat.formatArabicTime, as it wasn't provided in the original code
class AppFormat {
  static String formatArabicTime(String time) {
    // Simple placeholder logic
    if (time.length >= 5) {
      return time.substring(0, 5);
    }
    return time;
  }
}

class LandingPage extends StatelessWidget {
  final List<String> carouselImages;
  final bool hasUpcomingBooking;
  final List<Map<String, dynamic>> discountedFields;
  final String? featuredText1;
  final String? featuredText2;
  final onGoToFieldsPage;
  final int matchesPlayedCount;

  LandingPage({
    super.key,
    required this.carouselImages,
    required this.hasUpcomingBooking,
    required this.discountedFields,
    required this.featuredText1,
    required this.featuredText2,
    required this.onGoToFieldsPage,
    required this.matchesPlayedCount,
  });

  // Use a private final field for API URL
  final String? _apiUrl = dotenv.env['API_URL'];

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

  String normalizeUrl(String url) {
    if (url.startsWith("http")) {
      final uri = Uri.parse(url);
      final normalizedPath = uri.path.replaceAll(RegExp(r'/{2,}'), '/');
      return "${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}$normalizedPath";
    }

    // If relative, prepend API_URL and normalize
    final base =
        _apiUrl?.endsWith('/') == true ? _apiUrl!.substring(0, _apiUrl.length - 1) : _apiUrl ?? '';
    final path = url.startsWith('/') ? url : '/$url';
    return "$base$path".replaceAll(RegExp(r'/{2,}'), '/');
  }

  // Moved Icon logic to be a private method
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

  // --- NEW: Sport Category Navigation Button ---
  Widget _buildSportCategoryButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required String categoryType,
    required int categoryIndex,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          onGoToFieldsPage(categoryIndex);
        },
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(10),
          color: kPrimaryColor, // Use primary color for visibility
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

  // --- REFINED: Discounted Field Card (as before) ---
 Widget _buildDiscountedFieldCard(Map<String, dynamic> field, BuildContext context) {
  final imageUrl = getFirstImageUrl(field["field_images"] ?? []);
  final fieldName = field["field_name"] ?? "ملعب";
  final city = field["field_city"] ?? "";
  final location = field["field_location"] ?? "";
  final capacity = field["field_capacity"]?.toString() ?? "";
  final openTime = field["field_open_time"] ?? "";
  final closeTime = field["field_close_time"] ?? "";
  final fieldType = field["field_type"] ?? "";



  // Prices
  final originalPrice = double.tryParse(field["field_calculated_total_price"]?.toString() ?? "0") ?? 0;
  final discountPrice = double.tryParse(field["field_calculated_total_price_after_discount"]?.toString() ?? "0") ?? 0;

  final hasDiscount = field["field_has_discount"] == true;

  // --- Discount percentage ---
  int discountPercent = 0;
  if (hasDiscount && originalPrice > 0 && discountPrice > 0) {
    discountPercent = (100 - (discountPrice / originalPrice * 100)).round();
  }

  return GestureDetector(
    onTap: () {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => FieldDetailsPage(field: field)));
    },
    child: Container(
      width: 250,
      height: 240, // <-- increased (solves overflow)
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
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

    // ---------------- DISCOUNT BADGE (top-left) ----------------
    if (hasDiscount)
      Positioned(
        top: 8,
        left: 8,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.redAccent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            "خصم $discountPercent%",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),

    // ---------------- FIELD TYPE ICON (top-right) ----------------
    Positioned(
      top: 8,
      right: 8,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: kPrimaryColor,
          shape: BoxShape.circle,
        ),
        child: _getFieldTypeIcon(fieldType),
      ),
    ),
  ],
),

          // ---------------- TEXT SECTION ----------------
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Field Name
                Text(
                  fieldName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.redAccent),
                ),

                const SizedBox(height: 4),

                // City + Location
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "$city - $location",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.people, size: 14, color: Colors.redAccent),
                        const SizedBox(width: 4),
                        Text(
                          capacity,
                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // Prices
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          "د.ل ${discountPrice.toStringAsFixed(1)}",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.redAccent,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "د.ل ${originalPrice.toStringAsFixed(1)}",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ),
                  Row(
                    children: [
                      Text(
                        "${AppFormat.formatArabicTime(openTime)} - ${AppFormat.formatArabicTime(closeTime)}",
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
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
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: kBackgroundColor,
        body: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // --- 1. CAROUSEL HEADER (unchanged) ---
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
                            : ["assets/images/courtoDefaultField.jpg"])
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
                                  "assets/images/courtoDefaultField.jpg",
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

              // --- 2. CTA BUTTONS (unchanged) ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: kPadding),
                child: SizedBox(
                  width: double.infinity,
                  child: _ctaButtons(context),
                ),
              ),

              const SizedBox(height: 30),

              // --- 3. FEATURED TEXT MARQUEE (unchanged) ---
              _FeaturedTextMarquee(
                text1: featuredText1!.isEmpty
                    ? "مرحبا بكم في كورتو!"
                    : featuredText1,
                text2:
                    featuredText2!.isEmpty ? "اشحن احجز العب" : featuredText2,
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
                          // Tennis
                          _buildSportCategoryButton(
                            context: context,
                            label: "تنس",
                            icon: Icons.sports_baseball,
                            categoryType: "tennis",
                            categoryIndex: 3,
                          ),
                          const SizedBox(width: kPadding / 2),
                          // Padel
                          _buildSportCategoryButton(
                            context: context,
                            label: "بادل",
                            icon: Icons.sports_tennis_sharp,
                            categoryType: "padel",
                            categoryIndex: 4,
                          ),
                          const SizedBox(width: kPadding / 2),
                          // Carting
                          _buildSportCategoryButton(
                            context: context,
                            label: "كارتينج",
                            icon: Icons.airline_seat_recline_extra_rounded,
                            categoryType: "carting",
                            categoryIndex: 6,
                          ),
                          const SizedBox(width: kPadding / 2),
                          // Paintball
                          _buildSportCategoryButton(
                            context: context,
                            label: "بينتبول",
                            icon: Icons.format_paint_rounded,
                            categoryType: "paintball",
                            categoryIndex: 7,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // -----------------------------------------------------------------

              const SizedBox(height: 30),

              if (discountedFields.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: kPadding),
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      "العروض و المباريات",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: kPrimaryColor,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),
                SizedBox(
                  height: 240,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding:
                        const EdgeInsets.symmetric(horizontal: kPadding, vertical: 8),
                    itemCount: discountedFields.length,
                    itemBuilder: (context, index) {
                      return _buildDiscountedFieldCard(
                          discountedFields[index], context);
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

  // --- CTA Button Logic (unchanged) ---
  Widget _ctaButtons(BuildContext context) {
    if (AuthService.isLoggedIn) {
      return _loggedInButtons(context);
    } else {
      return _loginSignupButtons(context);
    }
  }

  // --- Logged Out Buttons (Login/Signup) (unchanged) ---
  Widget _loginSignupButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const LoginPage()));
            },
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(10),
              color: kPrimaryColor,
              child: Container(
                height: 120,
                padding: const EdgeInsets.all(8),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.login, color: Colors.white, size: 40),
                    SizedBox(height: 8),
                    Text(
                      "تسجيل الدخول",
                      style: TextStyle(
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
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SignupPage()));
            },
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(10),
              color: kPrimaryColor,
              child: Container(
                height: 120,
                padding: const EdgeInsets.all(8),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_add, color: Colors.white, size: 40),
                    SizedBox(height: 8),
                    Text(
                      "إنشاء حساب",
                      style: TextStyle(
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

  // --- Logged In Buttons (History/Count + Book Field) (unchanged) ---
  Widget _loggedInButtons(BuildContext context) {
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
                  borderRadius: BorderRadius.circular(10),
                  color: kPrimaryColor,
                  child: Container(
                    height: (buttonHeight - 4) / 2,
                    width: double.infinity,
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, color: Colors.white, size: 24),
                        SizedBox(height: 4),
                        Text(
                          "سجل الحجوزات",
                          style: TextStyle(
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
                borderRadius: BorderRadius.circular(10),
                color: kPrimaryColor,
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
                      const Text(
                        "مباريات لعبت",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
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
              borderRadius: BorderRadius.circular(10),
              color: kPrimaryColor,
              child: Container(
                height: buttonHeight,
                width: double.infinity,
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.stadium, color: Colors.white, size: 45),
                    SizedBox(height: 8),
                    Text(
                      "احجز ملعب",
                      style: TextStyle(
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

// --- REFINED: Featured Text Marquee with Fading Edges (unchanged) ---
class _FeaturedTextMarquee extends StatefulWidget {
  final String? text1;
  final String? text2;

  const _FeaturedTextMarquee({
    required this.text1,
    required this.text2,
  });

  @override
  _FeaturedTextMarqueeState createState() => _FeaturedTextMarqueeState();
}

class _FeaturedTextMarqueeState extends State<_FeaturedTextMarquee> {
  final ScrollController _scrollController = ScrollController();
  static const Duration scrollDuration = Duration(seconds: 20);

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
    return Container(
      height: 40,
      width: double.infinity,
      color: kPrimaryColor,
      child: ShaderMask(
        shaderCallback: (Rect bounds) {
          return const LinearGradient(
            colors: [
              Colors.white,
              Colors.transparent,
              Colors.transparent,
              Colors.white
            ],
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
    );
  }

  Widget _text(String? text, Color color) {
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
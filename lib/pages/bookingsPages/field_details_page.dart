import 'dart:convert';
import 'package:courto/app_bar.dart';
import 'package:courto/constants.dart';
import 'package:courto/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui' as ui;
import 'field_calendar_page.dart';

class FieldDetailsPage extends StatefulWidget {
  final Map<String, dynamic> field;

  const FieldDetailsPage({super.key, required this.field});

  @override
  State<FieldDetailsPage> createState() => _FieldDetailsPageState();
}

class _FieldDetailsPageState extends State<FieldDetailsPage> {
  final PageController _pageController = PageController(viewportFraction: 0.95);
  int _currentPage = 0;

  final String? apiUrl = dotenv.env['API_URL'];
  final apiKey = dotenv.env['API_KEY'];

  bool _isFavorite = false;
  bool _loadingFavorite = false;
  int? userId = AuthService.userData?["id"];

  double _fieldScore = 0.0;
  int _reviewCount = 0;
  bool _isLoadingReviews = true;

  String mappedFieldType = "";

  bool _isEnglish = false;

  // City name map (Arabic -> English)
  static const Map<String, String> _cityEnMap = {
    "طرابلس": "Tripoli",
    "مصراتة": "Misrata",
    "بنغازي": "Benghazi",
    "الزاوية": "Zawiya",
    "الخمس": "Khoms",
    "سرت": "Surt",
    "درنة": "Derna",
    "طبرق": "Tobruk",
    "سبها": "Sabha",
    "صبراتة": "Subrata",
    "زوارة": "Zuwara"
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

  String _cityNameLocalized(String? city) {
    final c = (city ?? '').trim();
    if (!_isEnglish) return c;
    return _cityEnMap[c] ?? c;
  }

  String _locationNameLocalized(String? location) {
    final l = (location ?? '').trim();
    if (!_isEnglish) return l;
    return _locationEnMap[l] ?? l;
  }

  @override
  void initState() {
    super.initState();

    _pageController.addListener(() {
      if (_pageController.page != null &&
          _pageController.page!.round() != _currentPage) {
        setState(() => _currentPage = _pageController.page!.round());
      }
    });

    if (AuthService.isLoggedIn) {
      checkFavorite();
    }
    fetchFieldReviews();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final newIsEnglish = Localizations.localeOf(context).languageCode == "en";
    if (newIsEnglish != _isEnglish) {
      _isEnglish = newIsEnglish;
      mapFieldTypes();
    } else if (mappedFieldType.isEmpty) {
      mapFieldTypes();
    }
  }

  Future<void> fetchFieldReviews() async {
    setState(() => _isLoadingReviews = true);
    final fieldId = widget.field["field_id"] ?? widget.field["id"];

    try {
      if (fieldId == null) {
        setState(() => _isLoadingReviews = false);
        return;
      }

      final res = await http.get(
        Uri.parse("${apiUrl}users/getFieldReviews/$fieldId"),
        headers: {"x-api-key": apiKey ?? ""},
      );

      if (res.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(res.body);
        if (!mounted) return;
        setState(() {
          _fieldScore =
              (data["field_score"] is num) ? data["field_score"].toDouble() : 0.0;
          _reviewCount = (data["field_review_count"] is num)
              ? data["field_review_count"].toInt()
              : 0;
        });
      }
    } catch (_) {
      // ignore
    } finally {
      if (mounted) setState(() => _isLoadingReviews = false);
    }
  }

  Future<void> checkFavorite() async {
    try {
      if (userId == null) return;

      final res = await http.get(
        Uri.parse("${apiUrl}users/getFavorites/$userId"),
        headers: {
          "Authorization": "Bearer ${AuthService.token}",
          "x-api-key": apiKey ?? "",
        },
      );

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        final fieldId = widget.field["field_id"] ?? widget.field["id"];
        final exists = data.any((fav) => fav["field_id"] == fieldId);

        if (mounted) setState(() => _isFavorite = exists);
      }
    } catch (_) {}
  }

  Future<void> toggleFavorite() async {
    if (_loadingFavorite) return;

    final fieldId = widget.field["field_id"] ?? widget.field["id"];

    final bool? confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Directionality(
          textDirection: _isEnglish ? TextDirection.ltr : TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
            title: Text(
              _isEnglish
                  ? (_isFavorite ? "Remove from favorites?" : "Add to favorites?")
                  : (_isFavorite ? "إزالة من المفضلة؟" : "إضافة إلى المفضلة؟"),
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: _isEnglish ? TextAlign.left : TextAlign.right,
            ),
            content: Text(
              _isEnglish
                  ? (_isFavorite
                      ? "Are you sure you want to remove this field from favorites?"
                      : "Do you want to add this field to your favorites?")
                  : (_isFavorite
                      ? "هل أنت متأكد أنك تريد إزالة هذا الملعب من المفضلة؟"
                      : "هل تريد إضافة هذا الملعب إلى قائمة المفضلة؟"),
              textAlign: _isEnglish ? TextAlign.left : TextAlign.right,
            ),
            actions: [
              TextButton(
                child: Text(_isEnglish ? "Cancel" : "إلغاء"),
                onPressed: () => Navigator.pop(context, false),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                ),
                child: Text(
                  _isEnglish ? (_isFavorite ? "Remove" : "Add") : (_isFavorite ? "إزالة" : "إضافة"),
                  style: const TextStyle(color: Colors.white),
                ),
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
        );
      },
    );

    if (confirm != true) return;

    setState(() => _loadingFavorite = true);
    final endpoint = _isFavorite ? "removeFavorite" : "addFavorite";

    try {
      final res = await http.post(
        Uri.parse("${apiUrl}users/$endpoint"),
        headers: {
          "Authorization": "Bearer ${AuthService.token}",
          "Content-Type": "application/json",
          "x-api-key": apiKey ?? "",
        },
        body: jsonEncode({"user_id": userId, "field_id": fieldId}),
      );

      if (res.statusCode == 200) {
        if (!mounted) return;
        setState(() => _isFavorite = !_isFavorite);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEnglish
                  ? (_isFavorite ? "Added to favorites" : "Removed from favorites")
                  : (_isFavorite ? "تمت الإضافة للمفضلة" : "تمت الإزالة من المفضلة"),
              textDirection: _isEnglish ? TextDirection.ltr : TextDirection.rtl,
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingFavorite = false);
    }
  }

  void mapFieldTypes() {
    final t = (widget.field["field_type"] ?? '').toString();
    if (_isEnglish) {
      switch (t) {
        case "football":
          mappedFieldType = "Football";
          break;
        case "basketball":
          mappedFieldType = "Basketball";
          break;
        case "tennis":
          mappedFieldType = "Tennis";
          break;
        case "padel":
          mappedFieldType = "Padel";
          break;
        default:
          mappedFieldType = "";
      }
    } else {
      switch (t) {
        case "football":
          mappedFieldType = "كرة قدم";
          break;
        case "basketball":
          mappedFieldType = "كرة سلة";
          break;
        case "tennis":
          mappedFieldType = "تنس";
          break;
        case "padel":
          mappedFieldType = "بادل";
          break;
        default:
          mappedFieldType = "";
      }
    }
  }

  Widget _buildInfoRow(IconData icon, String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color ?? Theme.of(context).colorScheme.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              textAlign: _isEnglish ? TextAlign.left : TextAlign.right,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _resolveImageUrl(String url) {
    if (url.startsWith("http")) return url;
    if (apiUrl == null || apiUrl!.trim().isEmpty) return url;
    final base = apiUrl!.endsWith('/')
        ? apiUrl!.substring(0, apiUrl!.length - 1)
        : apiUrl!;
    return "$base$url";
  }

  Widget _buildPillIndicator(int index) {
    final isCurrent = index == _currentPage;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isCurrent ? 20.0 : 8.0,
      height: 8.0,
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: isCurrent
            ? Theme.of(context).colorScheme.primary
            : Colors.white.withOpacity(0.7),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCarousel(List<dynamic> images) {
    return Container(
      margin: const EdgeInsets.only(top: 10.0),
      height: 250,
      child: Stack(
        children: [
          if (images.isNotEmpty)
            SizedBox(
              height: 250,
              child: PageView.builder(
                controller: _pageController,
                itemCount: images.length,
                itemBuilder: (context, index) {
                  final img = images[index]?.toString() ?? '';
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: Image.network(
                        _resolveImageUrl(img),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              color: Theme.of(context).colorScheme.primary,
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: const Center(
                              child: Icon(Icons.broken_image,
                                  color: Colors.grey, size: 50),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            )
          else
            Container(
              height: 250,
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              decoration: BoxDecoration(
                color: Colors.red[100],
                borderRadius: BorderRadius.circular(5),
              ),
              child: Center(
                child: Text(
                  _isEnglish ? 'No images' : 'لا توجد صور',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          if (images.isNotEmpty && images.length > 1)
            Positioned(
              bottom: 15,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children:
                    List.generate(images.length, (index) => _buildPillIndicator(index)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStarRating() {
    const totalStars = 5;
    final rating = _fieldScore;
    final reviewCount = _reviewCount;

    if (_isLoadingReviews) {
      return Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _isEnglish ? 'Loading...' : 'جاري التحميل...',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...List.generate(totalStars, (index) {
            final diff = rating - index;
            IconData iconData;
            if (diff >= 1.0) {
              iconData = Icons.star_rounded;
            } else if (diff > 0.0) {
              iconData = Icons.star_half_rounded;
            } else {
              iconData = Icons.star_border_rounded;
            }
            return Icon(
              iconData,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            );
          }),
          const SizedBox(width: 8),
          Text(
            rating > 0.1 ? rating.toStringAsFixed(1) : '0.0',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSecondary,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '(${reviewCount.toString()})',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceAndFavoriteCard(double totalPrice) {
    final priceLine = _isEnglish
        ? "${totalPrice.toStringAsFixed(2)} LYD / hour"
        : "${totalPrice.toStringAsFixed(2)} د.ل / الساعة";

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onPrimary,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Theme.of(context).colorScheme.primary),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment:
                _isEnglish ? CrossAxisAlignment.start : CrossAxisAlignment.start,
            children: [
              Text(
                priceLine,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              _buildStarRating(),
            ],
          ),
          AbsorbPointer(
            absorbing: _loadingFavorite,
            child: IconButton(
              icon: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[700],
                size: 30,
              ),
              onPressed: AuthService.isLoggedIn ? toggleFavorite : null,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final List<dynamic> images = widget.field["field_images"] ?? [];

    final double? totalPrice = (widget.field["field_has_discount"] == true)
        ? double.tryParse(
            (widget.field["field_calculated_total_price_after_discount"] ?? "0")
                .toString(),
          )
        : double.tryParse(
            (widget.field["field_calculated_total_price"] ?? "0").toString(),
          );

    final fieldName = !_isEnglish ? (widget.field["field_name"] ?? '').toString() : (widget.field["field_english_name"] ?? '').toString();
    final city = _cityNameLocalized(widget.field["field_city"]?.toString());

    final location = _locationNameLocalized(widget.field["field_location"]?.toString());

    final locationDetails =
        (widget.field["field_location_details"] ?? '').toString();
    final capacity = (widget.field["field_capacity"] ?? '').toString();
    final surface = (widget.field["field_surface_type"] ?? '').toString();
    final openTime = (widget.field["field_open_time"] ?? '').toString();
    final closeTime = (widget.field["field_close_time"] ?? '').toString();
    final description = (widget.field["field_description"] ?? '').toString();

    final pageDirection = _isEnglish ? ui.TextDirection.ltr : ui.TextDirection.rtl;

    Future<void> openMaps() async {
      final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${widget.field["field_latitude"]},${widget.field["field_longitude"]}'
      );      if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
  }

    return Directionality(
      textDirection: pageDirection,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: buildHomeAppBar(context),
        body: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageCarousel(images),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment:
                      _isEnglish ? CrossAxisAlignment.start : CrossAxisAlignment.start,
                  children: [
                    Text(
                      fieldName,
                      textAlign: _isEnglish ? TextAlign.left : TextAlign.right,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 15),
                    if (totalPrice != null) _buildPriceAndFavoriteCard(totalPrice),
                    const SizedBox(height: 25),
                    Container(
                      padding: const EdgeInsets.all(12.0),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onPrimary,
                        borderRadius: BorderRadius.circular(5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildInfoRow(
                            Icons.location_on_outlined,
                            "$city / $location",
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          if (locationDetails.isNotEmpty)
                          InkWell(
                            borderRadius: BorderRadius.circular(5),
                            onTap: openMaps,
                            child: Row(
                              children: [
                                Icon(Icons.map_outlined, color: Theme.of(context).colorScheme.primary),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    locationDetails,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                                Icon(Icons.open_in_new, size: 18, color: Colors.grey),
                              ],
                            ),
                          ),
                          _buildInfoRow(
                            Icons.stadium_outlined,
                            _isEnglish
                                ? (mappedFieldType.isEmpty
                                    ? "Field"
                                    : "$mappedFieldType field")
                                : "ملعب $mappedFieldType",
                          ),
                          _buildInfoRow(
                            Icons.people_alt_outlined,
                            _isEnglish ? "Players: $capacity" : "عدد الاعبين $capacity",
                          ),
                          if (surface.isNotEmpty)
                            _buildInfoRow(Icons.grass_outlined, surface),
                          _buildInfoRow(
                            Icons.access_time,
                            "${AppFormat.formatArabicTime(openTime)} - ${AppFormat.formatArabicTime(closeTime)}",
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                    Text(
                      description.isNotEmpty
                          ? description
                          : (_isEnglish
                              ? 'No description available.'
                              : 'لا يوجد وصف متاح.'),
                      textAlign: _isEnglish ? TextAlign.left : TextAlign.right,
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FieldCalendarPage(field: widget.field),
              ),
            );
          },
          backgroundColor: Theme.of(context).colorScheme.primary,
          icon: const Icon(Icons.calendar_month, color: Colors.white),
          label: Text(
            _isEnglish ? "View schedule" : "عرض المواعيد",
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }
}

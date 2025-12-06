import 'dart:convert';
import 'package:courto/app_bar.dart';
import 'package:courto/constants.dart';
import 'package:courto/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
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
  // Placeholder state for the favorite button
  bool _isFavorite = false; // FAVORITE STATUS
  bool _loadingFavorite = false; // avoid spam tapping
  final userId = AuthService.userData!["id"];
  final apiKey = dotenv.env['API_KEY'];

  // New state variables for reviews
  double _fieldScore = 0.0;
  int _reviewCount = 0;
  bool _isLoadingReviews = true;

  String mappedFieldType = "";

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      if (_pageController.page != null &&
          _pageController.page!.round() != _currentPage) {
        setState(() {
          _currentPage = _pageController.page!.round();
        });
      }
    });
    mapFieldTypes();
    checkFavorite();
    fetchFieldReviews(); // Call the new fetch method
  }

  // --- New Review Fetch Method ---
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
        headers: {
          "x-api-key": apiKey ?? "",
        },
      );

      if (res.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(res.body);
        setState(() {
          // Ensure we handle potentially null or incorrect types gracefully
          _fieldScore = (data["field_score"] is num)
              ? data["field_score"].toDouble()
              : 0.0;
          _reviewCount = (data["field_review_count"] is num)
              ? data["field_review_count"].toInt()
              : 0;
        });
      }
    } catch (e) {
      print("Error fetching field reviews: $e");
    } finally {
      setState(() => _isLoadingReviews = false);
    }
  }

  // Check if this field is already in favorites
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
        List data = jsonDecode(res.body);

        final fieldId = widget.field["field_id"] ?? widget.field["id"];

        final exists = data.any((fav) => fav["field_id"] == fieldId);

        setState(() {
          _isFavorite = exists;
        });
      }
    } catch (e) {
      print(e);
    }
  }

  // Toggle favorite
  Future<void> toggleFavorite() async {
    if (_loadingFavorite) return;

    final fieldId = widget.field["field_id"] ?? widget.field["id"];

    // 1 Show confirmation dialog BEFORE doing anything
    final bool? confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
            title: Text(
              _isFavorite ? "إزالة من المفضلة؟" : "إضافة إلى المفضلة؟",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Text(
              _isFavorite
                  ? "هل أنت متأكد أنك تريد إزالة هذا الملعب من المفضلة؟"
                  : "هل تريد إضافة هذا الملعب إلى قائمة المفضلة؟",
            ),
            actions: [
              TextButton(
                child: const Text("إلغاء"),
                onPressed: () => Navigator.pop(context, false),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
                child: Text(
                  _isFavorite ? "إزالة" : "إضافة",
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
        );
      },
    );

    // User cancelled dialog
    if (confirm == null || confirm == false) return;

    //2 Proceed with actual API call
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
        body: jsonEncode({
          "user_id": userId,
          "field_id": fieldId,
        }),
      );

      if (res.statusCode == 200) {
        setState(() {
          _isFavorite = !_isFavorite;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isFavorite ? "تمت الإضافة للمفضلة" : "تمت الإزالة من المفضلة",
              textDirection: TextDirection.rtl,
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      setState(() => _loadingFavorite = false);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void mapFieldTypes() {
    switch (widget.field["field_type"]) {
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

  // Info Row (Styled)
  Widget _buildInfoRow(IconData icon, String text,
      {Color color = Colors.redAccent}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
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
    final apiUrlBase =
        apiUrl!.endsWith('/') ? apiUrl!.substring(0, apiUrl!.length - 1) : apiUrl;
    return "$apiUrlBase$url";
  }

  Widget _buildPillIndicator(int index) {
    bool isCurrent = index == _currentPage;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isCurrent ? 20.0 : 8.0,
      height: 8.0,
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: isCurrent ? Colors.redAccent : Colors.white.withOpacity(0.7),
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

  // Image Carousel (Extracted)
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
                              color: Colors.redAccent,
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
                              child: Icon(
                                Icons.broken_image,
                                color: Colors.grey,
                                size: 50,
                              ),
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
              child: const Center(
                child: Text(
                  'لا توجد صور',
                  style: TextStyle(color: Colors.redAccent, fontSize: 18),
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
                children: List.generate(images.length, (index) {
                  return _buildPillIndicator(index);
                }),
              ),
            ),
        ],
      ),
    );
  }

  // Star Rating Placeholder (Updated)
  Widget _buildStarRatingPlaceholder() {
    const double totalStars = 5;
    
    // Use fetched data
    final double rating = _fieldScore;
    final int reviewCount = _reviewCount;

    if (_isLoadingReviews) {
      // Show a placeholder or loader while fetching
      return Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.redAccent),
            ),
            const SizedBox(width: 8),
            const Text('جاري التحميل...', style: TextStyle(color: Colors.black54)),
          ],
        ),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...List.generate(totalStars.toInt(), (index) {
            double difference = rating - index;
            IconData iconData;
            Color color = Colors.redAccent;

            if (difference >= 1.0) {
              iconData = Icons.star_rounded;
            } else if (difference > 0.0) {
              iconData = Icons.star_half_rounded;
            } else {
              iconData = Icons.star_border_rounded;
            }

            return Icon(
              iconData,
              color: color,
              size: 24,
            );
          }),
          const SizedBox(width: 8),
          Text(
            // Show 0.0 if rating is less than 0.1
            rating > 0.1 ? '${rating.toStringAsFixed(1)}' : '0.0', 
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '(${reviewCount.toString()})',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceAndFavoriteCard(double totalPrice) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${totalPrice.toStringAsFixed(2)} د.ل / الساعة",
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.redAccent),
              ),
              _buildStarRatingPlaceholder(), // Now uses fetched data
            ],
          ),
          
          // Favorite Button (Disable if loading)
          AbsorbPointer(
            absorbing: _loadingFavorite,
            child: IconButton(
              icon: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite ? Colors.redAccent : Colors.grey[700],
                size: 30,
              ),
              onPressed: toggleFavorite,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<dynamic> images = widget.field["field_images"] ?? [];

    final double? totalPrice = widget.field["field_has_discount"]
        ? double.tryParse(
            widget.field["field_calculated_total_price_after_discount"]
                .toString())
        : double.tryParse(widget.field["field_calculated_total_price"].toString());

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.red[50],
        appBar: buildHomeAppBar(context),
        body: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageCarousel(images),

              // Field Details
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Field Name
                    Text(
                      widget.field["field_name"] ?? '',
                      style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.redAccent),
                    ),
                    const SizedBox(height: 15),

                    _buildPriceAndFavoriteCard(totalPrice!),

                    const SizedBox(height: 25),

                    Container(
                      padding: const EdgeInsets.all(12.0),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
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
                              "${widget.field["field_city"] ?? ''} / ${widget.field["field_location"]}",
                              color: Colors.redAccent),
                          _buildInfoRow(Icons.map_outlined,
                              "${widget.field["field_location_details"] ?? ''}"),
                          _buildInfoRow(Icons.stadium_outlined, "ملعب $mappedFieldType"),
                          _buildInfoRow(Icons.people_alt_outlined,
                              "عدد الاعبين ${widget.field["field_capacity"] ?? ''}"),
                          _buildInfoRow(Icons.grass_outlined,
                              "${widget.field["field_surface_type"] ?? ''}"),
                          _buildInfoRow(
                            Icons.access_time,
                            "${AppFormat.formatArabicTime(widget.field["field_open_time"] ?? '')} - ${AppFormat.formatArabicTime(widget.field["field_close_time"] ?? '')}",
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    Text(
                      widget.field["field_description"] ?? 'لا يوجد وصف متاح.',
                      style: const TextStyle(
                          fontSize: 16, color: Colors.black54, height: 1.5),
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
          backgroundColor: Colors.redAccent,
          icon: const Icon(Icons.calendar_month, color: Colors.white),
          label: const Text(
            "عرض المواعيد",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }
}
import 'package:courto/app_bar.dart';
import 'package:courto/constants.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../services/auth_service.dart';
import 'field_calendar_page.dart';

class FieldDetailsPage extends StatefulWidget {
  final Map<String, dynamic> field;

  const FieldDetailsPage({super.key, required this.field});

  @override
  State<FieldDetailsPage> createState() => _FieldDetailsPageState();
}

class _FieldDetailsPageState extends State<FieldDetailsPage> {
  // 1. New: PageController for better control and viewportFraction
  final PageController _pageController = PageController(viewportFraction: 0.95);
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    // Listen to page changes to update the indicator state
    _pageController.addListener(() {
      // Use round() to handle partial scrolling and determine the active page
      if (_pageController.page != null && _pageController.page!.round() != _currentPage) {
        setState(() {
          _currentPage = _pageController.page!.round();
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Helper widget to build the information rows
  Widget _buildInfoRow(IconData icon, String text, {Color color = Colors.red}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  // Helper function to resolve image URL
  String _resolveImageUrl(String url) {
    // Ensuring the API URL doesn't have a trailing slash if the image URL is relative
    final apiUrlBase = apiUrl.endsWith('/') ? apiUrl.substring(0, apiUrl.length - 1) : apiUrl;
    return url.startsWith("http") ? url : "$apiUrlBase$url";
  }

  // New widget for the Pill-style Indicator
  Widget _buildPillIndicator(int index, int totalPages) {
    bool isCurrent = index == _currentPage;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      // Active pill is wider for styling
      width: isCurrent ? 16.0 : 8.0,
      height: 8.0,
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4), // Gives it the pill shape
        color: isCurrent
            ? Colors.red // Active color
            : Colors.white.withOpacity(0.7), // Inactive color
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<dynamic> images = widget.field["field_images"] ?? [];

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
              // Image Carousel Section: Using Container with Margin (instead of Padding)
              Container(
                margin: const EdgeInsets.only(top: 10.0),
                height: 220, // Keep height on the parent container
                child: Stack(
                  children: [
                    if (images.isNotEmpty)
                      SizedBox(
                        height: 220,
                        child: PageView.builder(
                          controller: _pageController, // Use the controller
                          itemCount: images.length,
                      
                          itemBuilder: (context, index) {
           
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(5.0), // Rounded corners for styling
                                child: Image.network(
                                  _resolveImageUrl(images[index].toString()),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.red,
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded /
                                                loadingProgress.expectedTotalBytes!
                                            : null,
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.red[100],
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
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: const Center(
                          child: Text(
                            'لا توجد صور',
                            style: TextStyle(color: Colors.red, fontSize: 18),
                          ),
                        ),
                      ),
                 
                    if (images.isNotEmpty && images.length > 1)
                      Positioned(
                        bottom: 10,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(images.length, (index) {
                            return _buildPillIndicator(index, images.length);
                          }),
                        ),
                      ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Field Name and Price
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Expanded(
                          child: Text(
                            widget.field["field_name"] ?? '',
                            style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.black),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            "${widget.field["field_price"] ?? 0} / الساعة",
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Information Section
                    _buildInfoRow(Icons.place, "${widget.field["field_city"] ?? ''} / ${widget.field["field_location"]}", color: Colors.red),
                    _buildInfoRow(Icons.map, "${widget.field["field_location_details"] ?? ''}"),
                    _buildInfoRow(Icons.people_alt, "${widget.field["field_capacity"] ?? ''} لاعبين"),
                    _buildInfoRow(Icons.grass, "${widget.field["field_surface_type"] ?? ''}"),
                    _buildInfoRow(
                      Icons.access_time,
                      "${AppFormat.formatArabicTime(widget.field["field_open_time"] ?? '')} - ${AppFormat.formatArabicTime(widget.field["field_close_time"] ?? '')}",
                    ),
                    const SizedBox(height: 20),
                    Text(
                      widget.field["field_description"] ?? '',
                      style: const TextStyle(fontSize: 16, color: Colors.black54),
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
          backgroundColor: Colors.red,
          icon: const Icon(Icons.calendar_today, color: Colors.white),
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
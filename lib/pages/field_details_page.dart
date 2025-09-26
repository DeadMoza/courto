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
  int _currentPage = 0;

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

  @override
  Widget build(BuildContext context) {
    final List<dynamic> images = widget.field["field_images"] ?? [];

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.red[50],
        appBar: AppBar(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          elevation: 0,
          title: Row(
            children: [
              Expanded(
                child: Text(
                  "${AuthService.userData?['full_name'] ?? ''}",
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.account_balance_wallet,
                        color: Colors.red, size: 22),
                    const SizedBox(width: 4),
                    Text(
                      AuthService.userData?['wallet_balance']?.toString() ?? '0',
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5.0),
                  child: Stack(
                    children: [
                      if (images.isNotEmpty)
                        SizedBox(
                          height: 250,
                          child: PageView.builder(
                            itemCount: images.length,
                            onPageChanged: (int page) {
                              setState(() {
                                _currentPage = page;
                              });
                            },
                            itemBuilder: (context, index) {
                              final url = images[index].toString();
                              final imageUrl = url.startsWith("http")
                                  ? url
                                  : "${apiUrl.substring(0, apiUrl.length - 1)}$url";
                              return Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
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
                                  return const Center(
                                    child: Icon(
                                      Icons.broken_image,
                                      color: Colors.grey,
                                      size: 50,
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        )
                      else
                        Container(
                          height: 250,
                          color: Colors.red[100],
                          child: const Center(
                            child: Text(
                              'لا توجد صور',
                              style: TextStyle(color: Colors.red, fontSize: 18),
                            ),
                          ),
                        ),
                      // Carousel Indicator
                      if (images.isNotEmpty && images.length > 1)
                        Positioned(
                          bottom: 10,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(images.length, (index) {
                              return Container(
                                width: 8.0,
                                height: 8.0,
                                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _currentPage == index
                                      ? Colors.red
                                      : Colors.white.withOpacity(0.5),
                                ),
                              );
                            }),
                          ),
                        ),
                    ],
                  ),
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
                    const Text(
                      "الوصف:",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
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
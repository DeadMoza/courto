import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import '../constants.dart';
import 'field_details_page.dart';

class FieldsListPage extends StatefulWidget {
  final int cityId;
  final List<Map<String, dynamic>> fields;
  final bool loading;
  final String? errorMessage;

  const FieldsListPage({
    super.key,
    required this.cityId,
    required this.fields,
    required this.loading,
    this.errorMessage,
  });

  @override
  State<FieldsListPage> createState() => _FieldsListPageState();
}

class _FieldsListPageState extends State<FieldsListPage> {
  final ScrollController _scrollController = ScrollController();
  bool _showFilter = true;

  @override
  void initState() {
    super.initState();
    // Removed _fetchFields() call

    _scrollController.addListener(() {
      if (_scrollController.position.userScrollDirection ==
          ScrollDirection.reverse) {
        if (_showFilter) setState(() => _showFilter = false);
      } else if (_scrollController.position.userScrollDirection ==
          ScrollDirection.forward) {
        if (!_showFilter) setState(() => _showFilter = true);
      }
    });
  }

  // Removed _fetchFields() method

  String getFirstImageUrl(List<dynamic> images) {
    if (images.isEmpty) return '';
    final url = images[0].toString();
    // prepend your API base URL if needed
    return url.startsWith("http") ? url : "${apiUrl.substring(0, apiUrl.length - 1)}$url";
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.red[50],
        body: SafeArea(
          child: Column(
            children: [
              // You can keep the filter logic here, but it's currently empty/implicit in the original code,
              // so I'm leaving the rest of the build method mostly as is, using widget.loading, widget.errorMessage, and widget.fields
              Expanded(
                child: widget.loading
                    ? const Center(child: CircularProgressIndicator(color: Colors.red))
                    : widget.errorMessage != null
                        ? Center(child: Text(widget.errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 16)))
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(12),
                            itemCount: widget.fields.length,
                            itemBuilder: (context, index) {
                              final field = widget.fields[index];
                              final imageUrl = getFirstImageUrl(field["field_images"] ?? []);

                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => FieldDetailsPage(field: field),
                                    ),
                                  );
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 14),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(5),
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.red.withOpacity(0.1),
                                        blurRadius: 6,
                                        offset: const Offset(0, 3),
                                      )
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (imageUrl.isNotEmpty)
                                        ClipRRect(
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                                          child: Image.network(
                                            imageUrl,
                                            width: double.infinity,
                                            height: 160,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      Padding(
                                        padding: const EdgeInsets.all(14),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    field["field_name"] ?? '',
                                                    style: const TextStyle(
                                                        fontSize: 18,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.black87),
                                                    overflow: TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Row(
                                                    children: [
                                                      const Icon(Icons.attach_money_rounded, color: Colors.red, size: 18),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        "${field["field_price"] ?? 0} / الساعة",
                                                        style: const TextStyle(fontSize: 15, color: Colors.black54),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Row(
                                                    children: [
                                                      const Icon(Icons.place, color: Colors.redAccent, size: 18),
                                                      const SizedBox(width: 4),
                                                      Expanded(
                                                        child: Text(
                                                          "${field["field_location"] ?? ''}",
                                                          style: const TextStyle(fontSize: 14, color: Colors.black54),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.red[50],
                                                    borderRadius: BorderRadius.circular(5),
                                                  ),
                                                  child: Text(
                                                    "${AppFormat.formatArabicTime(field["field_open_time"] ?? '')} - ${AppFormat.formatArabicTime(field["field_close_time"] ?? '')}",
                                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.red),
                                                  ),
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
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// import 'package:flutter/material.dart';
// import 'package:flutter/rendering.dart';
// import 'dart:ui' as ui;
// import '../constants.dart';
// import 'field_details_page.dart';

// // Assuming AppFormat is defined elsewhere (e.g., in constants.dart)
// // For this code to run, make sure AppFormat.formatArabicTime exists,
// // or uncomment the time formatting method if AppFormat is unavailable.

// class FieldsListPage extends StatefulWidget {
//   final int cityId;
//   final List<Map<String, dynamic>> fields;
//   final bool loading;
//   final String? errorMessage;

//   const FieldsListPage({
//     super.key,
//     required this.cityId,
//     required this.fields,
//     required this.loading,
//     this.errorMessage,
//   });

//   @override
//   State<FieldsListPage> createState() => _FieldsListPageState();
// }

// class _FieldsListPageState extends State<FieldsListPage> {
//   final ScrollController _scrollController = ScrollController();
//   // Using ValueNotifier for cleaner state management for a floating element
//   final ValueNotifier<bool> _showFilterNotifier = ValueNotifier(true);

//   @override
//   void initState() {
//     super.initState();

//     _scrollController.addListener(() {
//       final direction = _scrollController.position.userScrollDirection;
//       if (direction == ScrollDirection.reverse) {
//         if (_showFilterNotifier.value) _showFilterNotifier.value = false;
//       } else if (direction == ScrollDirection.forward) {
//         if (!_showFilterNotifier.value) _showFilterNotifier.value = true;
//       }
//     });
//   }

//   String getFirstImageUrl(List<dynamic> images) {
//     if (images.isEmpty) return 'https://via.placeholder.com/400x200?text=No+Image';
//     final url = images[0].toString();
//     // prepend your API base URL if needed
//     // Assuming apiUrl is available and formatted correctly in constants.dart
//     // Note: Removed substring logic for cleaner display, assuming apiUrl is the base.
//     return url.startsWith("http") ? url : "${apiUrl.endsWith('/') ? apiUrl.substring(0, apiUrl.length - 1) : apiUrl}$url";
//   }

//   @override
//   void dispose() {
//     _scrollController.dispose();
//     _showFilterNotifier.dispose();
//     super.dispose();
//   }
  
//   // A dedicated widget for the field card is better for code reuse and readability
//   Widget _buildFieldCard(Map<String, dynamic> field) {
//     final imageUrl = getFirstImageUrl(field["field_images"] ?? []);
//     final fieldName = field["field_name"] ?? 'ملعب غير مسمى';
//     final price = field["field_price"] ?? 0;
//     final location = field["field_location"] ?? 'موقع غير معروف';
//     final openTime = field["field_open_time"] ?? '';
//     final closeTime = field["field_close_time"] ?? '';
//     final capacity = field["field_capacity"] ?? 0;

//     return GestureDetector(
//       onTap: () {
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (_) => FieldDetailsPage(field: field)),
//         );
//       },
//       child: Container(
//         margin: const EdgeInsets.only(bottom: 16),
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(15),
//           color: Colors.white,
//           boxShadow: [
//             BoxShadow(
//               color: Colors.red.withOpacity(0.15),
//               blurRadius: 10,
//               offset: const Offset(0, 5),
//             )
//           ],
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Image Section
//             ClipRRect(
//               borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
//               child: Image.network(
//                 imageUrl,
//                 width: double.infinity,
//                 height: 180,
//                 fit: BoxFit.cover,
//                 loadingBuilder: (context, child, loadingProgress) {
//                   if (loadingProgress == null) return child;
//                   return Container(
//                     height: 180,
//                     color: Colors.grey[200],
//                     child: Center(
//                       child: CircularProgressIndicator(
//                         color: Colors.red,
//                         value: loadingProgress.expectedTotalBytes != null
//                             ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
//                             : null,
//                       ),
//                     ),
//                   );
//                 },
//                 errorBuilder: (context, error, stackTrace) => Container(
//                   height: 180,
//                   color: Colors.grey[300],
//                   child: const Center(
//                     child: Icon(Icons.sports_soccer, size: 40, color: Colors.red),
//                   ),
//                 ),
//               ),
//             ),

//             // Details Section
//             Padding(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Name and Rating (Placeholder)
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Expanded(
//                         child: Text(
//                           fieldName,
//                           style: const TextStyle(
//                               fontSize: 18,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.black),
//                           overflow: TextOverflow.ellipsis,
//                           maxLines: 1,
//                         ),
//                       ),
//                       // Rating Placeholder
//                       Row(
//                         children: [
//                           const Icon(Icons.star, color: Colors.amber, size: 18),
//                           const SizedBox(width: 4),
//                           Text(
//                             '4.5', // Replace with actual rating data
//                             style: TextStyle(fontSize: 14, color: Colors.grey[600]),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 10),

//                   // Location and Price Row
//                   Row(
//                     crossAxisAlignment: CrossAxisAlignment.end,
//                     children: [
//                       // Location
//                       const Icon(Icons.place, color: Colors.redAccent, size: 18),
//                       const SizedBox(width: 4),
//                       Expanded(
//                         child: Text(
//                           location,
//                           style: const TextStyle(fontSize: 14, color: Colors.black54),
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                       ),
//                       const SizedBox(width: 16),
//                       // Price
//                       Row(
//                         children: [
//                           const Icon(Icons.attach_money_rounded, color: Colors.green, size: 18),
//                           const SizedBox(width: 4),
//                           Text(
//                             "$price / الساعة",
//                             style: const TextStyle(
//                                 fontSize: 16,
//                                 color: Colors.green,
//                                 fontWeight: FontWeight.bold),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 12),
                  
//                   // Time and Capacity Row (Bottom tags)
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       // Time Tag
//                       Container(
//                         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//                         decoration: BoxDecoration(
//                           color: Colors.red[50],
//                           borderRadius: BorderRadius.circular(20),
//                           border: Border.all(color: Colors.red.withOpacity(0.5))
//                         ),
//                         child: Text(
//                           "${AppFormat.formatArabicTime(openTime)} - ${AppFormat.formatArabicTime(closeTime)}",
//                           style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.red),
//                         ),
//                       ),
                      
//                       // Capacity Tag (Styled as requested)
//                       Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           const Icon(Icons.people, size: 18, color: Colors.red),
//                           const SizedBox(width: 6),
//                           Container(
//                             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
//                             decoration: BoxDecoration(
//                               color: Colors.red,
//                               borderRadius: BorderRadius.circular(15),
//                             ),
//                             child: Text(
//                               "$capacity",
//                               style: const TextStyle(
//                                 fontSize: 13,
//                                 color: Colors.white,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Directionality(
//       textDirection: ui.TextDirection.rtl,
//       child: Scaffold(
//         backgroundColor: Colors.grey[50], // Lighter background
//         appBar: AppBar(
//           backgroundColor: Colors.red,
//           foregroundColor: Colors.white,
//           title: const Text('الملاعب المتاحة', style: TextStyle(fontWeight: FontWeight.bold)),
//           centerTitle: true,
//           // Removed back button if this is a main tab view
//           automaticallyImplyLeading: false, 
//         ),
//         body: SafeArea(
//           child: Stack(
//             children: [
//               // Main Content
//               _buildContent(),

//               // Floating Filter Button (Example of using _showFilterNotifier)
//               Align(
//                 alignment: Alignment.bottomCenter,
//                 child: ValueListenableBuilder<bool>(
//                   valueListenable: _showFilterNotifier,
//                   builder: (context, isVisible, child) {
//                     return AnimatedContainer(
//                       duration: const Duration(milliseconds: 300),
//                       height: isVisible ? 60 : 0,
//                       margin: const EdgeInsets.only(bottom: 16),
//                       child: isVisible 
//                           ? FloatingActionButton.extended(
//                               onPressed: () {
//                                 // Implement filter dialog/screen logic here
//                                 ScaffoldMessenger.of(context).showSnackBar(
//                                   const SnackBar(content: Text('فتح شاشة الفلترة/البحث')),
//                                 );
//                               },
//                               backgroundColor: Colors.redAccent,
//                               icon: const Icon(Icons.filter_list, color: Colors.white),
//                               label: const Text('تصفية النتائج', style: TextStyle(color: Colors.white)),
//                             )
//                           : const SizedBox.shrink(),
//                     );
//                   },
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildContent() {
//     if (widget.loading) {
//       return const Center(child: CircularProgressIndicator(color: Colors.red));
//     }

//     if (widget.errorMessage != null) {
//       return Center(
//         child: Padding(
//           padding: const EdgeInsets.all(24.0),
//           child: Text(
//             'حدث خطأ: ${widget.errorMessage}',
//             textAlign: TextAlign.center,
//             style: const TextStyle(color: Colors.red, fontSize: 16),
//           ),
//         ),
//       );
//     }

//     if (widget.fields.isEmpty) {
//       return const Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.search_off, size: 60, color: Colors.redAccent),
//             SizedBox(height: 10),
//             Text(
//               "لا توجد ملاعب متاحة حالياً في هذه المدينة.",
//               style: TextStyle(color: Colors.black54, fontSize: 16),
//             ),
//           ],
//         ),
//       );
//     }

//     // List View
//     return ListView.builder(
//       controller: _scrollController,
//       padding: const EdgeInsets.all(12),
//       itemCount: widget.fields.length,
//       itemBuilder: (context, index) {
//         return _buildFieldCard(widget.fields[index]);
//       },
//     );
//   }
// }
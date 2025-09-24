import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants.dart';

class FieldsListPage extends StatefulWidget {
  final int cityId;
  const FieldsListPage({super.key, required this.cityId});

  @override
  State<FieldsListPage> createState() => _FieldsListPageState();
}

class _FieldsListPageState extends State<FieldsListPage> {
  String selectedFilter = "الأقرب"; // default filter
  final List<String> filters = ["الأقرب", "الأرخص", "الأعلى تقييماً"];

  List<Map<String, dynamic>> fields = [];
  bool loading = true;
  String? errorMessage;

  final ScrollController _scrollController = ScrollController();
  bool _showFilter = true;

  @override
  void initState() {
    super.initState();
    _fetchFields();

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

  Future<void> _fetchFields() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final url = Uri.parse("${apiUrl}users/getFieldsByCity/${widget.cityId}");
      final res = await http.get(url);

      print("getFieldByCity response: ${res.body}");

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        if (data["fields"] != null && data["fields"] is List) {
          setState(() {
            fields = List<Map<String, dynamic>>.from(data["fields"]);
            loading = false;
          });
        } else {
          setState(() {
            fields = [];
            errorMessage = "لا توجد ملاعب في هذه المدينة";
            loading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = "فشل تحميل الملاعب";
          loading = false;
        });
      }
    } catch (e) {
      print("Error fetching fields: $e");
      setState(() {
        errorMessage = "فشل التحميل، تحقق من اتصالك بالإنترنت";
        loading = false;
      });
    }
  }

  String getFirstImageUrl(List<dynamic> images) {
    if (images.isEmpty) return '';
    final url = images[0].toString();
    // prepend your API base URL if needed
    return url.startsWith("http") ? url : "${apiUrl.substring(0, apiUrl.length - 1)}$url";
  }

  String formatTime(String timeStr) {
    try {
      final parts = timeStr.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final dt = DateTime(0, 1, 1, hour, minute);
      return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return timeStr;
    }
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
              AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                height: _showFilter ? 40 : 0,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _showFilter
                    ? Container(
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(5),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.filter_list, color: Colors.red),
                            const SizedBox(width: 6),
                            Expanded(
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: selectedFilter,
                                  items: filters
                                      .map((f) => DropdownMenuItem(
                                            value: f,
                                            child: Text(f),
                                          ))
                                      .toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      selectedFilter = value!;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : null,
              ),
              Expanded(
                child: loading
                    ? const Center(child: CircularProgressIndicator(color: Colors.red))
                    : errorMessage != null
                        ? Center(child: Text(errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 16)))
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(12),
                            itemCount: fields.length,
                            itemBuilder: (context, index) {
                              final field = fields[index];
                              final imageUrl = getFirstImageUrl(field["field_images"] ?? []);

                              return GestureDetector(
                                onTap: () {
                                  // Navigate to field details 
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
                                                    "${formatTime(field["field_open_time"] ?? '')} - ${formatTime(field["field_close_time"] ?? '')}",
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

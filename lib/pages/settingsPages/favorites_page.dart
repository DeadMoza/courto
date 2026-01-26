import 'package:courto/constants.dart';
import 'package:courto/pages/bookingsPages/field_details_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/auth_service.dart';

final apiUrl = dotenv.env['API_URL'];
final apiKey = dotenv.env['API_KEY'];

class FavoritesPage extends StatefulWidget {
  final List<Map<String, dynamic>> fields;
  const FavoritesPage({super.key, required this.fields});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  bool loading = true;
  List<Map<String, dynamic>> favorites = [];
  final userId = AuthService.userData!["id"];

  @override
  void initState() {
    super.initState();
    fetchFavorites();
  }

  Future<void> fetchFavorites() async {
    try {
      final response = await http.get(
        Uri.parse("${apiUrl}users/getFavorites/$userId"),
        headers: {
          "Authorization": "Bearer ${AuthService.token}",
          "x-api-key": apiKey ?? "",
        },
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        final List<int> favoriteIds =
            data.map<int>((item) => item["field_id"] as int).toList();

        final favoriteFields = widget.fields
            .where((field) => favoriteIds.contains(field["field_id"]))
            .toList();

        setState(() {
          favorites = favoriteFields;
          loading = false;
        });

      } else {
        showError("فشل تحميل المفضلة");
        setState(() => loading = false);
      }
    } catch (e) {
      print(e);
      showError("خطأ في الاتصال بالخادم");
      setState(() => loading = false);
    }
  }

  Future<void> removeFavorite(int fieldId) async {
    try {
      final response = await http.post(
        Uri.parse("${apiUrl}users/removeFavorite"),
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

      if (response.statusCode == 200) {
        setState(() {
          favorites.removeWhere((f) => f["field_id"] == fieldId);
        });

        ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
            content: Text(
              "تمت الإزالة من المفضلة",
              textDirection: TextDirection.rtl,
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      } else {
        showError("فشل حذف المفضلة");
      }
    } catch (e) {
      showError("تعذر الاتصال بالخادم");
    }
  }

  Future<void> confirmRemoveFavorite(int fieldId) async {
    final confirm = await showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text("تأكيد الحذف"),
          content: const Text("هل أنت متأكد من إزالة هذا الملعب من المفضلة؟"),
          actions: [
            TextButton(
              child: const Text("إلغاء", style: TextStyle(color: Colors.grey)),
              onPressed: () => Navigator.pop(context, false),
            ),
            TextButton(
              child: Text("حذف", style: TextStyle(color: Theme.of(context).colorScheme.primary)),
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      await removeFavorite(fieldId);
    }
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textDirection: TextDirection.rtl,
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  IconData _getFieldIcon(String? type) {
    switch (type?.toLowerCase()) {
      case "football":
      case "padbol":
        return Icons.sports_soccer;
      case "basketball":
        return Icons.sports_basketball;
      case "tennis":
      case "padel":
        return Icons.sports_tennis;
      case "volleyball":
        return Icons.sports_volleyball;
      case "paintball":
        return Icons.format_paint_rounded;
      case "carting":
        return Icons.airline_seat_recline_extra_rounded;
      case "golf":
        return Icons.golf_course;
      default:
        return Icons.sports;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text("المفضلة"),
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        ),
        body: loading
            ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
            : favorites.isEmpty
                ? const Center(
                    child: Text(
                      "لا توجد ملاعب مفضلة",
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: favorites.length,
                    itemBuilder: (context, index) {
                      final fav = favorites[index];

                      return Card(
                        elevation: 3,
                        color: Theme.of(context).colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        margin: const EdgeInsets.only(bottom: 14),
                        child: ListTile(
                          onTap: () {
                            // Directly use the full field object
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FieldDetailsPage(field: fav),
                              ),
                            );
                          },
                          contentPadding: const EdgeInsets.all(12),
                          leading: Icon(
                            _getFieldIcon(fav["field_type"]),
                            size: 34,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          title: Text(
                            fav["field_name"],
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("المدينة: ${fav["field_city"]}"),
                                Text("السعة: ${fav["field_capacity"]}"),
                                Text(
                                  "${AppFormat.formatArabicTime(fav["field_open_time"])} - "
                                  "${AppFormat.formatArabicTime(fav["field_close_time"])}",
                                ),
                              ],
                            ),
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.primary),
                            onPressed: () {
                              confirmRemoveFavorite(fav["field_id"]);
                            },
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

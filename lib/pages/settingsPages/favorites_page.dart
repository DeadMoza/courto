import 'package:courto/constants.dart';
import 'package:courto/pages/bookingsPages/field_details_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/auth_service.dart';
import 'package:courto/l10n/app_localizations.dart';

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
    final apiUrl = dotenv.env['API_URL'];
    final apiKey = dotenv.env['API_KEY'];

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
        showError(AppLocalizations.of(context)!.favoritesLoadFailed);
        setState(() => loading = false);
      }
    } catch (e) {
      print(e);
      showError(AppLocalizations.of(context)!.errorConnectionServer);
      setState(() => loading = false);
    }
  }

  Future<void> removeFavorite(int fieldId) async {
    final apiUrl = dotenv.env['API_URL'];
    final apiKey = dotenv.env['API_KEY'];
    final t = AppLocalizations.of(context)!;

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
              t.favoritesRemovedSuccess,
              textDirection: Directionality.of(context),
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      } else {
        showError(t.favoritesRemoveFailed);
      }
    } catch (e) {
      showError(t.supportErrorServer);
    }
  }

  Future<void> confirmRemoveFavorite(int fieldId) async {
    final t = AppLocalizations.of(context)!;

    final confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.confirmDeleteTitle),
        content: Text(t.confirmRemoveFavoriteBody),
        actions: [
          TextButton(
            child: Text(t.cancel, style: const TextStyle(color: Colors.grey)),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: Text(
              t.delete,
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
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
          textDirection: Directionality.of(context),
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

  String _fieldDisplayName(BuildContext context, Map<String, dynamic> field) {
    final lang = Localizations.localeOf(context).languageCode;
    if (lang == 'en') {
      final enName = field["field_english_name"];
      if (enName != null && enName.toString().trim().isNotEmpty) {
        return enName.toString();
      }
    }
    return (field["field_name"] ?? "").toString();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(t.favoritesTitle),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
      ),
      body: loading
          ? Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            )
          : favorites.isEmpty
              ? Center(
                  child: Text(
                    t.favoritesEmpty,
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
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
                          _fieldDisplayName(context, fav),
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
                              Text("${t.cityLabel}: ${fav["field_city"]}"),
                              Text("${t.capacityLabel}: ${fav["field_capacity"]}"),
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
    );
  }
}

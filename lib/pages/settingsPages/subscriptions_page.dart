import 'package:courto/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// =============================================================================
// SubscriptionsPage — list of the user's subscriptions
// =============================================================================
class SubscriptionsPage extends StatefulWidget {
  const SubscriptionsPage({super.key});

  @override
  State<SubscriptionsPage> createState() => _SubscriptionsPageState();
}

class _SubscriptionsPageState extends State<SubscriptionsPage> {
  List<Map<String, dynamic>> _subscriptions = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchSubscriptions();
  }

  bool get isEnglish => Localizations.localeOf(context).languageCode == 'en';

  Future<void> _fetchSubscriptions() async {
    setState(() {
      _loading = true;
      _error   = null;
    });
    try {
      final apiUrl = dotenv.env['API_URL'] ?? '';
      final token  = AuthService.token;

      final response = await http.get(
        Uri.parse('${apiUrl}users/getUserSubscriptions'),
        headers: {
          'x-api-key':     '${dotenv.env['API_KEY']}',
          'Authorization': 'Bearer $token',
        },
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200) {
        final data = body['data'] as List<dynamic>? ?? [];
        setState(() {
          _subscriptions =
              data.map((e) => Map<String, dynamic>.from(e)).toList();
        });
      } else {
        setState(() =>
            _error = body['error'] ?? 'Error loading subscriptions');
      }
    } catch (_) {
      setState(() =>
          _error = isEnglish ? 'Network error' : 'خطأ في الاتصال');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  static const Map<String, IconData> _planTypeIcon = {
    'chess':    Icons.grid_on_rounded,
    'academy':  Icons.directions_run,
    'swimming': Icons.pool,
    'fitness':  Icons.fitness_center,
    'arcade':   Icons.sports_esports,
  };

  Color _statusColor(String status) {
    switch (status) {
      case 'active':    return Colors.green;
      case 'expired':   return Colors.grey;
      case 'paused':    return Colors.orange;
      case 'cancelled': return Colors.red;
      default:          return Colors.grey;
    }
  }

  String _statusLabel(String status, bool en) {
    if (en) {
      switch (status) {
        case 'active':    return 'Active';
        case 'expired':   return 'Expired';
        case 'paused':    return 'Paused';
        case 'cancelled': return 'Cancelled';
        default:          return status;
      }
    } else {
      switch (status) {
        case 'active':    return 'نشط';
        case 'expired':   return 'منتهي';
        case 'paused':    return 'موقوف';
        case 'cancelled': return 'ملغي';
        default:          return status;
      }
    }
  }

  String _durationLabel(String d, bool en) {
    if (en) {
      switch (d) {
        case 'monthly':   return 'Monthly';
        case 'quarterly': return 'Quarterly';
        case 'annual':    return 'Annual';
      }
    } else {
      switch (d) {
        case 'monthly':   return 'شهري';
        case 'quarterly': return 'ربع سنوي';
        case 'annual':    return 'سنوي';
      }
    }
    return d;
  }

  String _formatDate(String? raw, bool en) {
    if (raw == null || raw.isEmpty) return '—';
    try {
      final d = DateTime.parse(raw);
      const enM = ['Jan','Feb','Mar','Apr','May','Jun',
                   'Jul','Aug','Sep','Oct','Nov','Dec'];
      const arM = ['يناير','فبراير','مارس','أبريل','مايو','يونيو',
                   'يوليو','أغسطس','سبتمبر','أكتوبر','نوفمبر','ديسمبر'];
      final m = en ? enM : arM;
      return en
          ? '${m[d.month - 1]} ${d.day}, ${d.year}'
          : '${d.day} ${m[d.month - 1]} ${d.year}';
    } catch (_) {
      return raw;
    }
  }

  Color _cardColor(BuildContext context) =>
      Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor;

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final en = isEnglish;
    final cs = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: en ? ui.TextDirection.ltr : ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: cs.primary,
          foregroundColor: Colors.white,
          title: Text(
            en ? 'My Subscriptions' : 'اشتراكاتي',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          elevation: 0,
        ),
        body: _buildBody(en, cs),
      ),
    );
  }

  Widget _buildBody(bool en, ColorScheme cs) {
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: cs.primary));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchSubscriptions,
              style: ElevatedButton.styleFrom(backgroundColor: cs.primary),
              child: Text(
                en ? 'Retry' : 'إعادة المحاولة',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }

    if (_subscriptions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.card_membership_outlined,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              en ? 'No subscriptions yet' : 'لا توجد اشتراكات بعد',
              style: TextStyle(
                fontSize:   16,
                fontWeight: FontWeight.w600,
                color:      Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: cs.primary,
      onRefresh: _fetchSubscriptions,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _subscriptions.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _buildCard(_subscriptions[i], en, cs),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> sub, bool en, ColorScheme cs) {
    final planName    = en
        ? (sub['plan_name_eng'] ?? sub['plan_name'] ?? '')
        : (sub['plan_name'] ?? '');
    final status      = (sub['status'] ?? '').toString();
    final statusColor = _statusColor(status);
    final duration    = _durationLabel((sub['duration_type'] ?? '').toString(), en);
    final startDate   = _formatDate(sub['original_start_date']?.toString() ?? sub['start_date']?.toString(), en);
    final endDate     = _formatDate(sub['end_date']?.toString(), en);
    final type        = (sub['type'] ?? '').toString().toLowerCase();
    final iconData    = _planTypeIcon[type] ?? Icons.card_membership;

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SubscriptionDetailsPage(subscription: sub),
          ),
        );
        // Refresh list when coming back (in case of renewal)
        _fetchSubscriptions();
      },
      child: Container(
        decoration: BoxDecoration(
          color:        _cardColor(context),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color:      Colors.black.withOpacity(0.07),
              blurRadius: 8,
              offset:     const Offset(0, 3),
            ),
          ],
          border: Border.all(
            color: statusColor.withOpacity(0.25),
            width: 1.2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Top row: icon + name + status badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width:  44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: cs.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(iconData, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          planName.toString(),
                          style: TextStyle(
                            fontSize:   16,
                            fontWeight: FontWeight.w800,
                            color:      cs.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          duration,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color:        statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withOpacity(0.4)),
                    ),
                    child: Text(
                      _statusLabel(status, en),
                      style: TextStyle(
                        fontSize:   11,
                        fontWeight: FontWeight.w700,
                        color:      statusColor,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),
              Divider(height: 1, color: Colors.grey.shade200),
              const SizedBox(height: 12),

              // Date row
              Row(
                children: [
                  _dateChip(
                    en ? 'Start' : 'البداية',
                    startDate,
                    Icons.play_circle_outline,
                    Colors.green,
                  ),
                  const SizedBox(width: 12),
                  _dateChip(
                    en ? 'End' : 'النهاية',
                    endDate,
                    Icons.stop_circle_outlined,
                    statusColor,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dateChip(String label, String value, IconData icon, Color iconColor) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 15, color: iconColor),
          const SizedBox(width: 5),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 10, color: Colors.grey.shade500)),
                Text(value,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


// =============================================================================
// SubscriptionDetailsPage
// =============================================================================
class SubscriptionDetailsPage extends StatefulWidget {
  final Map<String, dynamic> subscription;

  const SubscriptionDetailsPage({super.key, required this.subscription});

  @override
  State<SubscriptionDetailsPage> createState() =>
      _SubscriptionDetailsPageState();
}

class _SubscriptionDetailsPageState extends State<SubscriptionDetailsPage> {
  Map<String, dynamic> get sub => widget.subscription;
  bool _renewLoading = false;

  bool get isEnglish =>
      Localizations.localeOf(context).languageCode == 'en';

  // ── Static maps ───────────────────────────────────────────────────────────
  static const Map<String, String> _planTypeImage = {
    'chess':    'assets/images/courtoChess.png',
    'academy':  'assets/images/courtoTeams.jpg',
    'swimming': 'assets/images/courtoSwimming.png',
    'fitness':  'assets/images/courtoFitness.png',
    'arcade':   'assets/images/courtoArcade.png',
  };

  static const Map<String, IconData> _planTypeIcon = {
    'chess':    Icons.grid_on_rounded,
    'academy':  Icons.directions_run,
    'swimming': Icons.pool,
    'fitness':  Icons.fitness_center,
    'arcade':   Icons.sports_esports,
  };

  // ── Helpers ───────────────────────────────────────────────────────────────
  Color _statusColor(String status) {
    switch (status) {
      case 'active':    return Colors.green;
      case 'expired':   return Colors.grey;
      case 'paused':    return Colors.orange;
      case 'cancelled': return Colors.red;
      default:          return Colors.grey;
    }
  }

  String _statusLabel(String status, bool en) {
    if (en) {
      switch (status) {
        case 'active':    return 'Active';
        case 'expired':   return 'Expired';
        case 'paused':    return 'Paused';
        case 'cancelled': return 'Cancelled';
        default:          return status;
      }
    } else {
      switch (status) {
        case 'active':    return 'نشط';
        case 'expired':   return 'منتهي';
        case 'paused':    return 'موقوف';
        case 'cancelled': return 'ملغي';
        default:          return status;
      }
    }
  }

  String _durationLabel(String d, bool en) {
    if (en) {
      switch (d) {
        case 'monthly':   return 'Monthly';
        case 'quarterly': return 'Quarterly';
        case 'annual':    return 'Annual';
      }
    } else {
      switch (d) {
        case 'monthly':   return 'شهري';
        case 'quarterly': return 'ربع سنوي';
        case 'annual':    return 'سنوي';
      }
    }
    return d;
  }


  String _formatDate(String? raw, bool en) {
    if (raw == null || raw.isEmpty) return '—';
    try {
      final d = DateTime.parse(raw);
      const enM = [
        'January','February','March','April','May','June',
        'July','August','September','October','November','December',
      ];
      const arM = [
        'يناير','فبراير','مارس','أبريل','مايو','يونيو',
        'يوليو','أغسطس','سبتمبر','أكتوبر','نوفمبر','ديسمبر',
      ];
      final m = en ? enM : arM;
      return en
          ? '${m[d.month - 1]} ${d.day}, ${d.year}'
          : '${d.day} ${m[d.month - 1]} ${d.year}';
    } catch (_) {
      return raw;
    }
  }

  int? _daysRemaining(String? endRaw) {
    if (endRaw == null) return null;
    try {
      return DateTime.parse(endRaw).difference(DateTime.now()).inDays;
    } catch (_) {
      return null;
    }
  }

  void _showSnack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content:         Text(msg),
      backgroundColor: success ? Colors.green[700] : Colors.red[700],
      behavior:        SnackBarBehavior.floating,
    ));
  }

  // ── Renew API call ────────────────────────────────────────────────────────
  Future<void> _renewSubscription(String durationType) async {
    setState(() => _renewLoading = true);
    try {
      final apiUrl = dotenv.env['API_URL'] ?? '';
      final token  = AuthService.token;

      final response = await http.post(
        Uri.parse('${apiUrl}users/renewSubscription'),
        headers: {
          'x-api-key':     '${dotenv.env['API_KEY']}',
          'Content-Type':  'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'subscription_id': sub['subscription_id'],
          'duration_type':   durationType,
        }),
      );

      final body = jsonDecode(response.body);

      // Close the bottom sheet
      if (mounted) Navigator.pop(context);

      if (response.statusCode == 200 && body['success'] == true) {
        _showSnack(
          isEnglish ? 'Renewed successfully!' : 'تم التجديد بنجاح!',
          success: true,
        );
        // Pop back to list so it refreshes
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) Navigator.pop(context);
      } else {
        _showSnack(
          body['error'] ??
              (isEnglish ? 'Something went wrong' : 'حدث خطأ'),
        );
      }
    } catch (_) {
      if (mounted) Navigator.pop(context);
      _showSnack(isEnglish ? 'Network error' : 'خطأ في الاتصال');
    } finally {
      if (mounted) setState(() => _renewLoading = false);
    }
  }

  // ── Renew bottom sheet ────────────────────────────────────────────────────
  void _showRenewSheet() {
    final en = isEnglish;
    final cs = Theme.of(context).colorScheme;

    // Build available options from plan prices stored in sub
    final options = <Map<String, dynamic>>[];
    final mp = double.tryParse(sub['monthly_price']?.toString()   ?? '');
    final qp = double.tryParse(sub['quarterly_price']?.toString() ?? '');
    final ap = double.tryParse(sub['annual_price']?.toString()    ?? '');
    if (mp != null) options.add({'type': 'monthly',   'price': mp});
    if (qp != null) options.add({'type': 'quarterly', 'price': qp});
    if (ap != null) options.add({'type': 'annual',    'price': ap});

    // Default to the same duration they're currently on
    String selectedType = (sub['duration_type'] ?? '').toString();
    if (!options.any((o) => o['type'] == selectedType)) {
      selectedType = (options.isNotEmpty ? options.first['type'] : 'monthly') as String;
    }

    showModalBottomSheet(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) {
          String dlabel(String d) => _durationLabel(d, en);

          final selOpt = options.firstWhere(
            (o) => o['type'] == selectedType,
            orElse: () => options.isNotEmpty ? options.first : {'type': 'monthly', 'price': 0.0},
          );
          final selPrice = (selOpt['price'] as double?) ?? 0.0;

          return Directionality(
            textDirection: en ? ui.TextDirection.ltr : ui.TextDirection.rtl,
            child: Container(
              decoration: BoxDecoration(
                color:        Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24)),
              ),
              padding: EdgeInsets.fromLTRB(
                20, 16, 20,
                MediaQuery.of(context).viewInsets.bottom + 28,
              ),
              child: Column(
                mainAxisSize:      MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Handle bar
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color:        Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title
                  Text(
                    en ? 'Renew subscription' : 'تجديد الاشتراك',
                    style: TextStyle(
                      fontSize:   18,
                      fontWeight: FontWeight.w800,
                      color:      cs.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    en
                        ? 'Choose the period to renew for'
                        : 'اختر مدة التجديد',
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 20),

                  // Period tiles
                  if (options.isEmpty)
                    Center(
                      child: Text(
                        en ? 'No pricing available' : 'لا توجد أسعار متاحة',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    )
                  else
                    Row(
                      children: options.asMap().entries.map((e) {
                        final idx      = e.key;
                        final opt      = e.value;
                        final t        = opt['type'] as String;
                        final p        = (opt['price'] as double?) ?? 0.0;
                        final selected = selectedType == t;
                        final isLast   = idx == options.length - 1;

                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setSheet(() => selectedType = t),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: EdgeInsets.only(
                                right: en  && !isLast ? 8 : 0,
                                left:  !en && !isLast ? 8 : 0,
                              ),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 6),
                              decoration: BoxDecoration(
                                color: selected
                                    ? cs.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: selected
                                      ? cs.primary
                                      : Colors.grey.shade300,
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    dlabel(t),
                                    style: TextStyle(
                                      fontSize:   12,
                                      fontWeight: FontWeight.w700,
                                      color: selected
                                          ? Colors.white
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    en
                                        ? 'LYD ${p.toStringAsFixed(0)}'
                                        : 'د.ل ${p.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontSize:   14,
                                      fontWeight: FontWeight.w900,
                                      color: selected
                                          ? Colors.white
                                          : cs.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                  const SizedBox(height: 20),

                  // Summary row
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      color:        cs.primary.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: cs.primary.withOpacity(0.20)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.account_balance_wallet_outlined,
                                color: cs.primary, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              en ? 'Pay from wallet' : 'الدفع من المحفظة',
                              style: TextStyle(
                                fontSize:   13,
                                fontWeight: FontWeight.w600,
                                color:      cs.primary,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          en
                              ? 'LYD ${selPrice.toStringAsFixed(2)}'
                              : 'د.ل ${selPrice.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize:   17,
                            fontWeight: FontWeight.w900,
                            color:      cs.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Confirm button
                  SizedBox(
                    width:  double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _renewLoading || options.isEmpty
                          ? null
                          : () => _renewSubscription(selectedType),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 3,
                      ),
                      child: _renewLoading
                          ? const SizedBox(
                              width: 22, height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.refresh,
                                    color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  en
                                      ? 'Confirm renewal'
                                      : 'تأكيد التجديد',
                                  style: const TextStyle(
                                    fontSize:   16,
                                    fontWeight: FontWeight.w800,
                                    color:      Colors.white,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final en  = isEnglish;
    final cs  = Theme.of(context).colorScheme;

    final planName    = en
        ? (sub['plan_name_eng'] ?? sub['plan_name'] ?? '')
        : (sub['plan_name'] ?? '');
    final status      = (sub['status'] ?? '').toString();
    final statusColor = _statusColor(status);
    final duration    = _durationLabel((sub['duration_type'] ?? '').toString(), en);
    final startDate   = _formatDate(
        sub['original_start_date']?.toString() ?? sub['start_date']?.toString(), en);
    final endDate     = _formatDate(sub['end_date']?.toString(), en);
    final daysLeft    = _daysRemaining(sub['end_date']?.toString());
    final amountPaid  = double.tryParse(sub['amount_paid']?.toString() ?? '');
    final type        = (sub['type'] ?? '').toString().toLowerCase();
    final imagePath   = _planTypeImage[type];
    final iconData    = _planTypeIcon[type] ?? Icons.card_membership;

    return Directionality(
      textDirection: en ? ui.TextDirection.ltr : ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: CustomScrollView(
          slivers: [

            // ── Hero header ───────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 250,
              pinned:         true,
              backgroundColor: cs.primary,
              foregroundColor: Colors.white,
              automaticallyImplyLeading: false,
              leading: Padding(
                padding: const EdgeInsets.all(8),
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.30),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.parallax,
                background: Stack(
                  fit: StackFit.expand,
                  children: [

                    // Background image or solid color
                    if (imagePath != null)
                      Image.asset(imagePath, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Container(color: cs.primary))
                    else
                      Container(color: cs.primary),

                    // Gradient overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin:  Alignment.topCenter,
                          end:    Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.45),
                            Colors.black.withOpacity(0.65),
                          ],
                        ),
                      ),
                    ),

                    // Content
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 44),

                        Container(
                          width:  72, height: 72,
                          decoration: BoxDecoration(
                            color:  Colors.white.withOpacity(0.18),
                            shape:  BoxShape.circle,
                            border: Border.all(
                                color: Colors.white.withOpacity(0.5),
                                width: 2),
                          ),
                          child: Icon(iconData,
                              color: Colors.white, size: 36),
                        ),
                        const SizedBox(height: 12),

                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            planName.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize:   22,
                              fontWeight: FontWeight.w900,
                              color:      Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(
                            color:        statusColor.withOpacity(0.20),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: statusColor.withOpacity(0.5)),
                          ),
                          child: Text(
                            _statusLabel(status, en),
                            style: const TextStyle(
                              fontSize:   13,
                              fontWeight: FontWeight.w700,
                              color:      Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Body ─────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── Subscription info card ────────────────────────────
                    _sectionCard(
                      context: context,
                      cs:      cs,
                      children: [
                        _detailRow(
                          context: context,
                          icon:  Icons.play_circle_outline,
                          color: Colors.green,
                          label: en ? 'Start date' : 'تاريخ البداية',
                          value: startDate,
                        ),
                        _divider(),
                        _detailRow(
                          context: context,
                          icon:  Icons.stop_circle_outlined,
                          color: statusColor,
                          label: en ? 'End date' : 'تاريخ النهاية',
                          value: endDate,
                        ),
                        if (daysLeft != null && status == 'active') ...[
                          _divider(),
                          _detailRow(
                            context: context,
                            icon:  Icons.hourglass_bottom_outlined,
                            color: daysLeft <= 7 ? Colors.orange : cs.primary,
                            label: en ? 'Days remaining' : 'الأيام المتبقية',
                            value: daysLeft > 0
                                ? (en ? '$daysLeft days' : '$daysLeft يوم')
                                : (en ? 'Expires today' : 'ينتهي اليوم'),
                          ),
                        ],
                        _divider(),
                        _detailRow(
                          context: context,
                          icon:  Icons.refresh,
                          color: cs.primary,
                          label: en ? 'Duration' : 'مدة الاشتراك',
                          value: duration,
                        ),
                        if (amountPaid != null) ...[
                          _divider(),
                          _detailRow(
                            context: context,
                            icon:  Icons.account_balance_wallet_outlined,
                            color: cs.primary,
                            label: en ? 'Amount paid' : 'المبلغ المدفوع',
                            value: en
                                ? 'LYD ${amountPaid.toStringAsFixed(2)}'
                                : 'د.ل ${amountPaid.toStringAsFixed(2)}',
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ── Subscriber details ────────────────────────────────
                    _sectionLabel(
                        en ? 'Subscriber details' : 'بيانات المشترك',
                        context),
                    const SizedBox(height: 10),
                    _sectionCard(
                      context: context,
                      cs:      cs,
                      children: [
                        _detailRow(
                          context: context,
                          icon:  Icons.person_outline,
                          color: cs.primary,
                          label: en ? 'Full name' : 'الاسم الكامل',
                          value: sub['full_name']?.toString() ?? '—',
                        ),
                        _divider(),
                        _detailRow(
                          context: context,
                          icon:  Icons.phone_outlined,
                          color: cs.primary,
                          label: en ? 'Phone' : 'رقم الهاتف',
                          value: sub['phone_number']?.toString() ?? '—',
                        ),
                        _divider(),
                        _detailRow(
                          context: context,
                          icon:  Icons.cake_outlined,
                          color: cs.primary,
                          label: en ? 'Birth date' : 'تاريخ الميلاد',
                          value: _formatDate(
                              sub['birth_date']?.toString(), en),
                        ),
                        if ((sub['school']?.toString() ?? '').isNotEmpty) ...[
                          _divider(),
                          _detailRow(
                            context: context,
                            icon:  Icons.school_outlined,
                            color: cs.primary,
                            label: en ? 'School' : 'المدرسة',
                            value: sub['school'].toString(),
                          ),
                        ],
                        if ((sub['grade']?.toString() ?? '').isNotEmpty) ...[
                          _divider(),
                          _detailRow(
                            context: context,
                            icon:  Icons.grade_outlined,
                            color: cs.primary,
                            label: en ? 'Grade' : 'الصف',
                            value: sub['grade'].toString(),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ── Renew button (hidden for cancelled) ───────────────
                    if (status != 'cancelled')
                      SizedBox(
                        width:  double.infinity,
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: _showRenewSheet,
                          icon: const Icon(Icons.refresh),
                          label: Text(
                            en ? 'Renew / Extend' : 'تجديد / تمديد',
                            style: const TextStyle(
                              fontSize:   15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: cs.primary,
                            side: BorderSide(color: cs.primary, width: 1.5),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Shared UI helpers ─────────────────────────────────────────────────────
  Widget _sectionLabel(String text, BuildContext context) => Text(
    text,
    style: TextStyle(
      fontSize:      13,
      fontWeight:    FontWeight.w700,
      color:         Colors.grey.shade500,
      letterSpacing: 0.4,
    ),
  );

  Widget _sectionCard({
    required BuildContext context,
    required ColorScheme  cs,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ??
               Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset:     const Offset(0, 3),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _detailRow({
    required BuildContext context,
    required IconData     icon,
    required Color        color,
    required String       label,
    required String       value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width:  36,
            height: 36,
            decoration: BoxDecoration(
              color:        color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade500)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Divider(
    height:    1,
    indent:    16,
    endIndent: 16,
    color:     Colors.grey.shade200,
  );
}
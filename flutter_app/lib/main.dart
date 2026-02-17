import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const StylistReportsApp());
}

const String apiBaseUrl =
    'https://script.google.com/macros/s/AKfycbxt1nLwXMzv0hf4oyf90TkDg8zxM_GzeGOkXIcc297aC2b2ygvFmoT0hC2XgTYkD3fy/exec';

const String _cacheStylistsKey = 'cache_stylists';
const String _cacheReportsKey = 'cache_reports';
const String _cacheLastSyncKey = 'cache_last_sync';
const String _filterMonthKey = 'filter_month';
const String _filterStartKey = 'filter_start';
const String _filterEndKey = 'filter_end';
const String _filterSearchKey = 'filter_search';
const String _filterSortIndexKey = 'filter_sort_index';
const String _filterSortAscKey = 'filter_sort_asc';

class StylistReportsApp extends StatelessWidget {
  const StylistReportsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0F766E),
      brightness: Brightness.light,
    );

    return MaterialApp(
      title: 'DATool',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        textTheme: GoogleFonts.spaceGroteskTextTheme(),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
      home: const StylistHomePage(),
    );
  }
}

class StylistHomePage extends StatefulWidget {
  const StylistHomePage({super.key});

  @override
  State<StylistHomePage> createState() => _StylistHomePageState();
}

class _StylistHomePageState extends State<StylistHomePage> {
  final ApiClient _apiClient = ApiClient();
  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _tokenFocus = FocusNode();

  bool _isLoading = false;
  String? _errorMessage;
  String? _stylistName;
  String? _token;
  DateTime? _lastSync;
  String? _lastErrorDetail;
  List<Report> _allReports = [];
  List<Report> _filteredReports = [];
  List<String> _availableMonths = [];
  String? _selectedMonth;
  DateTime? _startDate;
  DateTime? _endDate;
  String _searchQuery = '';
  int _sortColumnIndex = 0;
  bool _sortAscending = true;
  bool _isRefreshing = false;

  @override
  void dispose() {
    _tokenController.dispose();
    _searchController.dispose();
    _tokenFocus.dispose();
    super.dispose();
  }

  Future<CachedPayload?> _loadCachedPayload() async {
    final prefs = await SharedPreferences.getInstance();
    final stylistsRaw = prefs.getString(_cacheStylistsKey);
    final reportsRaw = prefs.getString(_cacheReportsKey);
    if (stylistsRaw == null || reportsRaw == null) {
      return null;
    }

    try {
      final stylistsJson = jsonDecode(stylistsRaw) as List<dynamic>;
      final reportsJson = jsonDecode(reportsRaw) as List<dynamic>;
      final stylists = stylistsJson
          .map((item) => Stylist.fromJson(item as Map<String, dynamic>))
          .toList();
      final reports = reportsJson
          .map((item) => Report.fromJson(item as Map<String, dynamic>))
          .toList();
      final lastSyncRaw = prefs.getString(_cacheLastSyncKey);
      final lastSync =
          lastSyncRaw == null ? null : DateTime.tryParse(lastSyncRaw);
      return CachedPayload(
        stylists: stylists,
        reports: reports,
        lastSync: lastSync,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveCache({
    required List<Stylist> stylists,
    required List<Report> reports,
    required DateTime lastSync,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _cacheStylistsKey,
      jsonEncode(stylists.map((item) => item.toJson()).toList()),
    );
    await prefs.setString(
      _cacheReportsKey,
      jsonEncode(reports.map((item) => item.toJson()).toList()),
    );
    await prefs.setString(_cacheLastSyncKey, lastSync.toIso8601String());
  }

  Future<void> _loadFilterState() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedMonth = prefs.getString(_filterMonthKey);
    _startDate = _parseStoredDate(prefs.getString(_filterStartKey));
    _endDate = _parseStoredDate(prefs.getString(_filterEndKey));
    _searchQuery = prefs.getString(_filterSearchKey) ?? '';
    _searchController.text = _searchQuery;
    _sortColumnIndex = prefs.getInt(_filterSortIndexKey) ?? 0;
    _sortAscending = prefs.getBool(_filterSortAscKey) ?? true;
    if (_selectedMonth != null && !_availableMonths.contains(_selectedMonth)) {
      _selectedMonth = null;
    }
  }

  Future<void> _persistFilterState() async {
    final prefs = await SharedPreferences.getInstance();
    if (_selectedMonth == null) {
      await prefs.remove(_filterMonthKey);
    } else {
      await prefs.setString(_filterMonthKey, _selectedMonth!);
    }
    if (_startDate == null) {
      await prefs.remove(_filterStartKey);
    } else {
      await prefs.setString(_filterStartKey, _startDate!.toIso8601String());
    }
    if (_endDate == null) {
      await prefs.remove(_filterEndKey);
    } else {
      await prefs.setString(_filterEndKey, _endDate!.toIso8601String());
    }
    await prefs.setString(_filterSearchKey, _searchQuery);
    await prefs.setInt(_filterSortIndexKey, _sortColumnIndex);
    await prefs.setBool(_filterSortAscKey, _sortAscending);
  }

  Future<void> _login() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your access token.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _lastErrorDetail = null;
    });

    final cached = await _loadCachedPayload();
    var usedCache = false;

    if (cached != null) {
      final cachedStylist = cached.stylists.firstWhere(
        (item) => item.token == token,
        orElse: () => const Stylist(name: '', token: ''),
      );

      if (cachedStylist.name.isNotEmpty) {
        final cachedReports = cached.reports
            .where((report) => report.stylist == cachedStylist.name)
            .toList();

        if (!mounted) {
          return;
        }

        setState(() {
          _stylistName = cachedStylist.name;
          _token = token;
          _allReports = cachedReports;
          _availableMonths = _buildMonthOptions(cachedReports);
          _filteredReports = List.from(cachedReports);
          _lastSync = cached.lastSync;
          _isLoading = false;
          _isRefreshing = true;
        });

        await _loadFilterState();
        _applyFilters();
        usedCache = true;
      }
    }

    final synced = await _syncFromApi(token, isBackground: usedCache);
    if (!synced && !usedCache) {
      _tokenFocus.requestFocus();
    }
  }

  Future<bool> _syncFromApi(String token, {required bool isBackground}) async {
    if (!mounted) {
      return false;
    }
    setState(() {
      _isRefreshing = isBackground;
      _lastErrorDetail = null;
    });

    try {
      final stylists = await _apiClient.fetchStylists();
      final stylist = stylists.firstWhere(
        (item) => item.token == token,
        orElse: () => const Stylist(name: '', token: ''),
      );

      if (stylist.name.isEmpty) {
        if (!mounted) {
          return false;
        }
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
          _errorMessage = 'Invalid token. Please try again.';
          _lastErrorDetail = 'Token not found in stylist list.';
        });
        return false;
      }

      final reports = await _apiClient.fetchReports();
      final stylistReports = reports
          .where((report) => report.stylist == stylist.name)
          .toList();

      final now = DateTime.now();
      await _saveCache(
        stylists: stylists,
        reports: reports,
        lastSync: now,
      );

      if (!mounted) {
        return false;
      }

      setState(() {
        _stylistName = stylist.name;
        _token = token;
        _allReports = stylistReports;
        _availableMonths = _buildMonthOptions(stylistReports);
        if (_selectedMonth != null && !_availableMonths.contains(_selectedMonth)) {
          _selectedMonth = null;
        }
        _lastSync = now;
        _isLoading = false;
        _isRefreshing = false;
        _errorMessage = null;
        _lastErrorDetail = null;
      });

      if (!isBackground) {
        await _loadFilterState();
      }
      _applyFilters();
      return true;
    } catch (error) {
      if (!mounted) {
        return false;
      }
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
        _errorMessage = _stylistName == null
            ? 'Unable to load reports. Please try again.'
            : 'Sync failed. Showing cached data.';
        _lastErrorDetail = error.toString();
      });
      return false;
    }
  }

  void _logout() {
    setState(() {
      _stylistName = null;
      _token = null;
      _lastSync = null;
      _lastErrorDetail = null;
      _tokenController.clear();
      _searchController.clear();
      _allReports = [];
      _filteredReports = [];
      _availableMonths = [];
      _selectedMonth = null;
      _startDate = null;
      _endDate = null;
      _searchQuery = '';
      _sortColumnIndex = 0;
      _sortAscending = true;
      _isRefreshing = false;
    });
  }

  void _applyMonthFilter(String? month) {
    setState(() {
      _selectedMonth = month?.isEmpty == true ? null : month;
      if (_selectedMonth != null) {
        _startDate = null;
        _endDate = null;
      }
    });
    _applyFilters();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initialDate = isStart
        ? (_startDate ?? DateTime.now())
        : (_endDate ?? _startDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2015),
      lastDate: DateTime(2035),
    );

    if (picked == null) {
      return;
    }

    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = picked;
        }
      } else {
        _endDate = picked;
        if (_startDate != null && _startDate!.isAfter(picked)) {
          _startDate = picked;
        }
      }
      if (_startDate != null || _endDate != null) {
        _selectedMonth = null;
      }
    });
    _applyFilters();
  }

  void _clearDateFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    _applyFilters();
  }

  Future<void> _pickDateRange() async {
    final initialRange = _startDate != null && _endDate != null
        ? DateTimeRange(start: _startDate!, end: _endDate!)
        : null;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2015),
      lastDate: DateTime(2035),
      initialDateRange: initialRange,
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _startDate = picked.start;
      _endDate = picked.end;
      _selectedMonth = null;
    });
    _applyFilters();
  }

  void _updateSearch(String value) {
    setState(() {
      _searchQuery = value;
    });
    _applyFilters();
  }

  Future<void> _retrySync() async {
    if (_token == null) {
      return;
    }
    await _syncFromApi(_token!, isBackground: true);
  }

  List<Report> _sortReports(List<Report> reports) {
    final sorted = List<Report>.from(reports);
    sorted.sort((a, b) {
      int result;
      switch (_sortColumnIndex) {
        case 0:
          final aDate = a.dateValue ?? DateTime(1900);
          final bDate = b.dateValue ?? DateTime(1900);
          result = aDate.compareTo(bDate);
          break;
        case 1:
          result = a.invoiceNumber.compareTo(b.invoiceNumber);
          break;
        case 2:
          result = a.stylist.compareTo(b.stylist);
          break;
        case 3:
          result = a.customerName.compareTo(b.customerName);
          break;
        case 4:
          result = a.amount.compareTo(b.amount);
          break;
        case 5:
          result = a.invoiceTotal.compareTo(b.invoiceTotal);
          break;
        default:
          result = 0;
      }
      return _sortAscending ? result : -result;
    });
    return sorted;
  }

  String _formatDateRangeLabel() {
    final formatter = DateFormat('MMM d');
    if (_startDate == null && _endDate == null) {
      return 'Date range';
    }
    if (_startDate != null && _endDate != null) {
      return '${formatter.format(_startDate!)} - ${formatter.format(_endDate!)}';
    }
    if (_startDate != null) {
      return 'From ${formatter.format(_startDate!)}';
    }
    return 'To ${formatter.format(_endDate!)}';
  }

  void _applyFilters() {
    var filtered = List<Report>.from(_allReports);

    if (_selectedMonth != null) {
      filtered = filtered
          .where((report) => report.monthLabel == _selectedMonth)
          .toList();
    }

    if (_startDate != null || _endDate != null) {
      filtered = filtered.where((report) {
        final date = report.dateValue;
        if (date == null) {
          return false;
        }
        if (_startDate != null && date.isBefore(_startDate!)) {
          return false;
        }
        if (_endDate != null && date.isAfter(_endDate!)) {
          return false;
        }
        return true;
      }).toList();
    }

    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.trim().toLowerCase();
      filtered = filtered.where((report) {
        return report.customerName.toLowerCase().contains(query) ||
            report.invoiceNumber.toLowerCase().contains(query);
      }).toList();
    }

    filtered = _sortReports(filtered);

    setState(() {
      _filteredReports = filtered;
    });

    _persistFilterState();
  }

  Future<void> _exportCsv() async {
    if (_filteredReports.isEmpty) {
      setState(() {
        _errorMessage = 'No rows to export.';
      });
      return;
    }

    final rows = <List<dynamic>>[
      [
        'Invoice Date',
        'Invoice Number',
        'Stylist',
        'Customer Name',
        'Amount',
        'Invoice Amount',
      ],
      ..._filteredReports.map(
        (report) => [
          report.formattedDate,
          report.invoiceNumber,
          report.stylist,
          report.customerName,
          report.amount.toStringAsFixed(2),
          report.invoiceTotal.toStringAsFixed(2),
        ],
      ),
    ];

    final csvData = const ListToCsvConverter().convert(rows);
    final bytes = Uint8List.fromList(utf8.encode(csvData));
    final timestamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final filename = 'stylist_reports_$timestamp';

    await FileSaver.instance.saveFile(
      name: filename,
      bytes: bytes,
      ext: 'csv',
      mimeType: MimeType.csv,
    );
  }

  List<String> _buildMonthOptions(List<Report> reports) {
    final months = reports
        .map((report) => report.monthLabel)
        .whereType<String>()
        .toSet()
        .toList();
    months.sort((a, b) {
      final aDate = DateFormat('MMMM yyyy').parse(a);
      final bDate = DateFormat('MMMM yyyy').parse(b);
      return bDate.compareTo(aDate);
    });
    return months;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF7F3E9), Color(0xFFE5F6F1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            const Positioned(
              top: -120,
              left: -80,
              child: _Orb(color: Color(0xFFF2C572), size: 220),
            ),
            const Positioned(
              bottom: -140,
              right: -60,
              child: _Orb(color: Color(0xFF6BD3C5), size: 260),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 600;
                  return SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompact ? 16 : 28,
                      vertical: isCompact ? 20 : 28,
                    ),
                    child: Align(
                      alignment:
                          isCompact ? Alignment.topCenter : Alignment.center,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 350),
                        child: _stylistName == null
                            ? _buildLoginCard(context, isCompact)
                            : _buildDashboard(context, isCompact),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginCard(BuildContext context, bool isCompact) {
    return ConstrainedBox(
      key: const ValueKey('login'),
      constraints: const BoxConstraints(maxWidth: 420),
      child: Card(
        elevation: 10,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: EdgeInsets.all(isCompact ? 20 : 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F766E),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.bar_chart, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stylist Reports',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Enter your token to continue',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.black54),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (_errorMessage != null)
                _MessageBanner(
                  text: _errorMessage!,
                  detail: _lastErrorDetail,
                  tone: MessageTone.error,
                ),
              const SizedBox(height: 16),
              TextField(
                controller: _tokenController,
                focusNode: _tokenFocus,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Access token',
                  hintText: 'Enter your token',
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _login(),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Access portal'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, bool isCompact) {
    final cardWidth = MediaQuery.of(context).size.width * 0.95;
    return ConstrainedBox(
      key: const ValueKey('dashboard'),
      constraints: const BoxConstraints(maxWidth: 1100),
      child: SizedBox(
        width: cardWidth.clamp(320, 1100),
        child: Card(
          elevation: 12,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
          child: Padding(
            padding: EdgeInsets.all(isCompact ? 18 : 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                isCompact
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, $_stylistName',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Token: ${_token ?? ''}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.black54),
                          ),
                          const SizedBox(height: 8),
                          _buildSyncStatus(context),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: OutlinedButton.icon(
                              onPressed: _logout,
                              icon: const Icon(Icons.logout),
                              label: const Text('Logout'),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome, $_stylistName',
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Token: ${_token ?? ''}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: Colors.black54),
                                ),
                                const SizedBox(height: 8),
                                _buildSyncStatus(context),
                              ],
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: _logout,
                            icon: const Icon(Icons.logout),
                            label: const Text('Logout'),
                          ),
                        ],
                      ),
                const SizedBox(height: 20),
                if (isCompact)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          labelText: 'Search',
                          hintText: 'Customer or invoice number',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: _updateSearch,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String?>(
                        value: _selectedMonth,
                        decoration: const InputDecoration(
                          labelText: 'Month',
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('All months'),
                          ),
                          ..._availableMonths.map(
                            (month) => DropdownMenuItem<String?>(
                              value: month,
                              child: Text(month),
                            ),
                          ),
                        ],
                        onChanged: _applyMonthFilter,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed:
                            _selectedMonth != null ? null : _pickDateRange,
                        icon: const Icon(Icons.date_range),
                        label: Text(_formatDateRangeLabel()),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                        ),
                      ),
                      if (_startDate != null || _endDate != null) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _clearDateFilters,
                            child: const Text('Clear dates'),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _exportCsv,
                        icon: const Icon(Icons.download),
                        label: const Text('Export CSV'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F766E),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  )
                else
                  Wrap(
                    spacing: 16,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: 260,
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            labelText: 'Search',
                            hintText: 'Customer or invoice number',
                            prefixIcon: Icon(Icons.search),
                          ),
                          onChanged: _updateSearch,
                        ),
                      ),
                      SizedBox(
                        width: 220,
                        child: DropdownButtonFormField<String?>(
                          value: _selectedMonth,
                          decoration: const InputDecoration(
                            labelText: 'Month',
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('All months'),
                            ),
                            ..._availableMonths.map(
                              (month) => DropdownMenuItem<String?>(
                                value: month,
                                child: Text(month),
                              ),
                            ),
                          ],
                          onChanged: _applyMonthFilter,
                        ),
                      ),
                      _DateButton(
                        label: 'From',
                        date: _startDate,
                        onPressed: _selectedMonth != null
                            ? null
                            : () => _pickDate(isStart: true),
                      ),
                      _DateButton(
                        label: 'To',
                        date: _endDate,
                        onPressed: _selectedMonth != null
                            ? null
                            : () => _pickDate(isStart: false),
                      ),
                      if (_startDate != null || _endDate != null)
                        TextButton(
                          onPressed: _clearDateFilters,
                          child: const Text('Clear dates'),
                        ),
                      ElevatedButton.icon(
                        onPressed: _exportCsv,
                        icon: const Icon(Icons.download),
                        label: const Text('Export CSV'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F766E),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 20),
                _buildSummaryTiles(context, isCompact),
                const SizedBox(height: 16),
                if (_errorMessage != null)
                  _MessageBanner(
                    text: _errorMessage!,
                    detail: _lastErrorDetail,
                    tone: MessageTone.error,
                  ),
                const SizedBox(height: 16),
                _buildTable(context, isCompact),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTable(BuildContext context, bool isCompact) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_filteredReports.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F9F9),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            const Icon(Icons.inbox_outlined, size: 42, color: Colors.black38),
            const SizedBox(height: 12),
            Text(
              'No reports found for this period.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.black54),
            ),
          ],
        ),
      );
    }

    final columns = [
      'Invoice Date',
      'Invoice Number',
      'Stylist',
      'Customer Name',
      'Amount',
      'Invoice Amount',
    ];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color(0xFFF9F9F9),
      ),
      child: isCompact
          ? Column(
              children: _filteredReports
                  .map(
                    (report) => Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE4E4E4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            report.customerName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          _InfoRow(label: 'Invoice', value: report.invoiceNumber),
                          _InfoRow(label: 'Date', value: report.formattedDate),
                          _InfoRow(
                            label: 'Amount',
                            value: report.amount.toStringAsFixed(2),
                          ),
                          _InfoRow(
                            label: 'Invoice Total',
                            value: report.invoiceTotal.toStringAsFixed(2),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                sortColumnIndex: _sortColumnIndex,
                sortAscending: _sortAscending,
                columns: List.generate(
                  columns.length,
                  (index) => DataColumn(
                    label: Text(
                      columns[index],
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    onSort: (columnIndex, ascending) {
                      setState(() {
                        _sortColumnIndex = columnIndex;
                        _sortAscending = ascending;
                      });
                      _applyFilters();
                    },
                  ),
                ),
                rows: _filteredReports
                    .map(
                      (report) => DataRow(
                        cells: [
                          DataCell(Text(report.formattedDate)),
                          DataCell(Text(report.invoiceNumber)),
                          DataCell(Text(report.stylist)),
                          DataCell(Text(report.customerName)),
                          DataCell(Text(report.amount.toStringAsFixed(2))),
                          DataCell(Text(report.invoiceTotal.toStringAsFixed(2))),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
    );
  }

  Widget _buildSummaryTiles(BuildContext context, bool isCompact) {
    final count = _filteredReports.length;
    final totalAmount = _filteredReports.fold<double>(
      0,
      (sum, report) => sum + report.amount,
    );
    final totalInvoice = _filteredReports.fold<double>(
      0,
      (sum, report) => sum + report.invoiceTotal,
    );

    if (isCompact) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: _SummaryTile(
              label: 'Count',
              value: count.toString(),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: _SummaryTile(
              label: 'Amount',
              value: totalAmount.toStringAsFixed(2),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: _SummaryTile(
              label: 'Invoice Total',
              value: totalInvoice.toStringAsFixed(2),
            ),
          ),
        ],
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        SizedBox(
          width: 190,
          child: _SummaryTile(
            label: 'Count',
            value: count.toString(),
          ),
        ),
        SizedBox(
          width: 190,
          child: _SummaryTile(
            label: 'Amount',
            value: totalAmount.toStringAsFixed(2),
          ),
        ),
        SizedBox(
          width: 190,
          child: _SummaryTile(
            label: 'Invoice Total',
            value: totalInvoice.toStringAsFixed(2),
          ),
        ),
      ],
    );
  }

  Widget _buildSyncStatus(BuildContext context) {
    final label = _lastSync == null
        ? 'Last sync: never'
        : 'Last sync: ${DateFormat('MMM d, yyyy HH:mm').format(_lastSync!)}';

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colors.black54),
        ),
        if (_isRefreshing)
          const SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        if (_lastErrorDetail != null && _lastErrorDetail!.isNotEmpty)
          TextButton.icon(
            onPressed: _retrySync,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Retry sync'),
          ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4E4E4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.black54),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.black54),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.label,
    required this.date,
    required this.onPressed,
  });

  final String label;
  final DateTime? date;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final text = date == null ? label : DateFormat('yyyy-MM-dd').format(date!);
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.calendar_today),
      label: Text(text),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}

class _MessageBanner extends StatelessWidget {
  const _MessageBanner({
    required this.text,
    required this.tone,
    this.detail,
  });

  final String text;
  final String? detail;
  final MessageTone tone;

  @override
  Widget build(BuildContext context) {
    final background = switch (tone) {
      MessageTone.error => const Color(0xFFFFE5E5),
      MessageTone.info => const Color(0xFFE6F7F3),
    };
    final foreground = switch (tone) {
      MessageTone.error => const Color(0xFFB42318),
      MessageTone.info => const Color(0xFF0F766E),
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            tone == MessageTone.error ? Icons.error_outline : Icons.info_outline,
            color: foreground,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: foreground),
                ),
                if (detail != null && detail!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      detail!,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: foreground.withOpacity(0.8)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.35),
      ),
    );
  }
}

enum MessageTone { error, info }

class Stylist {
  const Stylist({required this.name, required this.token});

  final String name;
  final String token;

  factory Stylist.fromJson(Map<String, dynamic> json) {
    return Stylist(
      name: (json['name'] ?? '').toString(),
      token: (json['token'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'token': token,
    };
  }
}

class Report {
  Report({
    required this.rawDate,
    required this.invoiceNumber,
    required this.stylist,
    required this.customerName,
    required this.amount,
    required this.invoiceTotal,
  }) {
    dateValue = _parseDate(rawDate);
    monthLabel = dateValue == null
        ? null
        : DateFormat('MMMM yyyy').format(dateValue!);
  }

  final String rawDate;
  final String invoiceNumber;
  final String stylist;
  final String customerName;
  final double amount;
  final double invoiceTotal;
  DateTime? dateValue;
  String? monthLabel;

  String get formattedDate {
    if (dateValue == null) {
      return rawDate;
    }
    return DateFormat('yyyy-MM-dd').format(dateValue!);
  }

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      rawDate: (json['date'] ?? '').toString(),
      invoiceNumber: (json['invoiceNumber'] ?? '').toString(),
      stylist: (json['stylist'] ?? '').toString(),
      customerName: (json['customerName'] ?? '').toString(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      invoiceTotal: (json['invoiceTotal'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': rawDate,
      'invoiceNumber': invoiceNumber,
      'stylist': stylist,
      'customerName': customerName,
      'amount': amount,
      'invoiceTotal': invoiceTotal,
    };
  }
}

class CachedPayload {
  const CachedPayload({
    required this.stylists,
    required this.reports,
    required this.lastSync,
  });

  final List<Stylist> stylists;
  final List<Report> reports;
  final DateTime? lastSync;
}

class ApiClient {
  final http.Client _client = http.Client();

  Future<List<Stylist>> fetchStylists() async {
    final uri = Uri.parse(apiBaseUrl).replace(queryParameters: {
      'action': 'stylists',
    });
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch stylists');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['success'] != true) {
      throw Exception(data['error'] ?? 'Stylists unavailable');
    }
    final list = (data['stylists'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    return list.map(Stylist.fromJson).toList();
  }

  Future<List<Report>> fetchReports() async {
    final uri = Uri.parse(apiBaseUrl).replace(queryParameters: {
      'action': 'reports',
    });
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch reports');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['success'] != true) {
      throw Exception(data['error'] ?? 'Reports unavailable');
    }
    final list = (data['reports'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    return list.map(Report.fromJson).toList();
  }
}

DateTime? _parseDate(String raw) {
  if (raw.isEmpty) {
    return null;
  }

  final direct = DateTime.tryParse(raw);
  if (direct != null) {
    return direct;
  }

  final cleaned = raw.replaceFirst(RegExp(r'GMT.*$'), '').trim();
  for (final format in [
    DateFormat('EEE MMM dd yyyy HH:mm:ss'),
    DateFormat('EEE MMM dd yyyy'),
  ]) {
    try {
      return format.parse(cleaned);
    } catch (_) {}
  }

  return null;
}

DateTime? _parseStoredDate(String? raw) {
  if (raw == null || raw.isEmpty) {
    return null;
  }
  return DateTime.tryParse(raw);
}

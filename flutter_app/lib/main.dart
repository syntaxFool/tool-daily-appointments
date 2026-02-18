import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'constants/app_constants.dart';
import 'models/data_models.dart';
import 'services/api_client.dart';
import 'services/cache_service.dart';
import 'utils/report_utils.dart';
import 'widgets/common_widgets.dart';

void main() {
  runApp(const StylistReportsApp());
}

class StylistReportsApp extends StatelessWidget {
  const StylistReportsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(primaryColorSeed),
      brightness: Brightness.light,
    );

    return MaterialApp(
      title: appTitle,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        textTheme: GoogleFonts.spaceGroteskTextTheme(),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
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
  late final ApiClient _apiClient;
  late final CacheService _cacheService;
  late final TextEditingController _tokenController;
  late final TextEditingController _searchController;
  late final FocusNode _tokenFocus;

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
  void initState() {
    super.initState();
    _apiClient = ApiClient();
    _cacheService = CacheService();
    _tokenController = TextEditingController();
    _searchController = TextEditingController();
    _tokenFocus = FocusNode();
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _searchController.dispose();
    _tokenFocus.dispose();
    super.dispose();
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

    final cached = await _cacheService.loadCachedPayload();
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
          _availableMonths = buildMonthOptions(cachedReports);
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
      await _cacheService.saveCache(
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
        _availableMonths = buildMonthOptions(stylistReports);
        if (_selectedMonth != null &&
            !_availableMonths.contains(_selectedMonth)) {
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

  Future<void> _pickDateRange() async {
    final initialRange = _startDate != null && _endDate != null
        ? DateTimeRange(start: _startDate!, end: _endDate!)
        : null;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(minYear),
      lastDate: DateTime(maxYear),
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

  List<Report> _sortReports(List<Report> reports) {
    final sorted = List<Report>.from(reports);
    sorted.sort((a, b) {
      int result;
      switch (_sortColumnIndex) {
        case 0:
          final aDate = a.dateValue ?? DateTime(minYear);
          final bDate = b.dateValue ?? DateTime(minYear);
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

  Future<void> _loadFilterState() async {
    final state = await _cacheService.loadFilterState(_availableMonths);
    setState(() {
      _selectedMonth = state.selectedMonth;
      _startDate = state.startDate;
      _endDate = state.endDate;
      _searchQuery = state.searchQuery;
      _searchController.text = _searchQuery;
      _sortColumnIndex = state.sortColumnIndex;
      _sortAscending = state.sortAscending;
    });
  }

  Future<void> _persistFilterState() async {
    final state = FilterState(
      selectedMonth: _selectedMonth,
      startDate: _startDate,
      endDate: _endDate,
      searchQuery: _searchQuery,
      sortColumnIndex: _sortColumnIndex,
      sortAscending: _sortAscending,
    );
    await _cacheService.persistFilterState(state);
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

  void _clearDateFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    _applyFilters();
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
            Positioned(
              top: -120,
              left: -80,
              child: Orb(
                color: const Color(orbYellow),
                size: orbSize,
              ),
            ),
            Positioned(
              bottom: -140,
              right: -60,
              child: Orb(
                color: const Color(orbTeal),
                size: orbSizeL,
              ),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact =
                      constraints.maxWidth < compactLayoutWidthThreshold;
                  return SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompact ? 16 : 28,
                      vertical: isCompact ? 20 : 28,
                    ),
                    child: Align(
                      alignment: isCompact
                          ? Alignment.topCenter
                          : Alignment.center,
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(largeRadius),
        ),
        child: Padding(
          padding: EdgeInsets.all(isCompact ? compactPadding : defaultPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(primaryColorSeed),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.bar_chart,
                        color: Colors.white),
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
                MessageBanner(
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(extraphoneRadius),
          ),
          child: Padding(
            padding: EdgeInsets.all(
                isCompact ? compactPadding : defaultPadding),
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
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildSyncStatus(context),
                              ),
                              OutlinedButton.icon(
                                onPressed: _logout,
                                icon: const Icon(Icons.logout),
                                label: const Text('Logout'),
                              ),
                            ],
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome, $_stylistName',
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 12),
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
                        decoration:
                            const InputDecoration(labelText: 'Month'),
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
                        onPressed: _selectedMonth != null
                            ? null
                            : _pickDateRange,
                        icon: const Icon(Icons.date_range),
                        label: Text(
                          formatDateRangeLabel(_startDate, _endDate),
                        ),
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
                          backgroundColor: const Color(primaryColorSeed),
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
                            hintText: 'Customer or invoice',
                            prefixIcon: Icon(Icons.search),
                          ),
                          onChanged: _updateSearch,
                        ),
                      ),
                      SizedBox(
                        width: 220,
                        child: DropdownButtonFormField<String?>(
                          value: _selectedMonth,
                          decoration:
                              const InputDecoration(labelText: 'Month'),
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
                      DateButton(
                        label: 'From',
                        date: _startDate,
                        onPressed: _selectedMonth != null
                            ? null
                            : () => _pickDateRange(),
                      ),
                      DateButton(
                        label: 'To',
                        date: _endDate,
                        onPressed: _selectedMonth != null
                            ? null
                            : () => _pickDateRange(),
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
                          backgroundColor: const Color(primaryColorSeed),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 20),
                _buildSummaryTiles(context, isCompact),
                const SizedBox(height: 16),
                if (_errorMessage != null)
                  MessageBanner(
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

  Widget _buildSummaryTiles(BuildContext context, bool isCompact) {
    final summary = calculateSummary(_filteredReports);

    if (isCompact) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: SummaryTile(
              label: 'Count',
              value: summary.count.toString(),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: SummaryTile(
              label: 'Amount',
              value: summary.totalAmount.toStringAsFixed(2),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: SummaryTile(
              label: 'Invoice Total',
              value: summary.totalInvoiceAmount.toStringAsFixed(2),
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
          child: SummaryTile(
            label: 'Count',
            value: summary.count.toString(),
          ),
        ),
        SizedBox(
          width: 190,
          child: SummaryTile(
            label: 'Amount',
            value: summary.totalAmount.toStringAsFixed(2),
          ),
        ),
        SizedBox(
          width: 190,
          child: SummaryTile(
            label: 'Invoice Total',
            value: summary.totalInvoiceAmount.toStringAsFixed(2),
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
            const Icon(Icons.inbox_outlined,
                size: 42, color: Colors.black38),
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
                          InfoRow(label: 'Invoice', value: report.invoiceNumber),
                          InfoRow(label: 'Date', value: report.formattedDate),
                          InfoRow(
                            label: 'Amount',
                            value: report.amount.toStringAsFixed(2),
                          ),
                          InfoRow(
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
                          DataCell(
                              Text(report.invoiceTotal.toStringAsFixed(2))),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
    );
  }
}

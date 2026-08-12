import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../models/stock_lookup_result.dart';
import '../../services/stock_service.dart';
import '../../services/zebra_scan_service.dart';

class StockLookupScreen extends StatefulWidget {
  const StockLookupScreen({super.key});

  @override
  State<StockLookupScreen> createState() => _StockLookupScreenState();
}

class _StockLookupScreenState extends State<StockLookupScreen> {
  static const _accent = Color(0xFF2E7D32);

  final MobileScannerController _controller =
      MobileScannerController(facing: CameraFacing.front);
  final StockService _service = StockService();
  final TextEditingController _searchController = TextEditingController();

  List<StockLookupResultModel>? _results;
  String? _searchedFor;
  bool _isLoading = false;
  String? _error;
  DateTime? _lastScanTime;
  StreamSubscription<String>? _zebraSub;

  @override
  void initState() {
    super.initState();
    // Zebra hardware trigger scans (via DataWedge) feed the same handler
    // as the camera preview below.
    _zebraSub = ZebraScanService.instance.onScan.listen(_handleScan);
  }

  void _handleScan(String code) {
    final now = DateTime.now();
    if (_lastScanTime != null &&
        now.difference(_lastScanTime!) < const Duration(seconds: 1)) {
      return;
    }
    _lastScanTime = now;

    HapticFeedback.mediumImpact();
    _searchController.text = code;
    _performLookup(code);
  }

  Future<void> _performLookup(String rawInput) async {
    final input = rawInput.trim();
    if (input.isEmpty || _isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await _service.lookup(input);
      if (!mounted) return;
      setState(() {
        _results = results;
        _searchedFor = input;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int get _totalUnits =>
      _results?.fold<int>(0, (sum, r) => sum + r.totalCount) ?? 0;

  @override
  void dispose() {
    _zebraSub?.cancel();
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    final scanWindow = Rect.fromLTWH(
      0,
      0,
      MediaQuery.of(context).size.width - 40,
      220,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Stock Lookup",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            /// HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                top: 120,
                left: 20,
                right: 20,
                bottom: 30,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(35)),
              ),
              child: Column(
                children: [
                  const Text(
                    "Enter a product code, number, or scan a barcode",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: _performLookup,
                      decoration: InputDecoration(
                        hintText: "Product code or number",
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 14),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search, color: _accent),
                          onPressed: () =>
                              _performLookup(_searchController.text),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// SCANNER
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              height: 220,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: Stack(
                  children: [
                    MobileScanner(
                      controller: _controller,
                      scanWindow: scanWindow,
                      onDetect: (capture) {
                        if (capture.barcodes.isEmpty) return;
                        final code = capture.barcodes.first.rawValue;
                        if (code != null) _handleScan(code);
                      },
                    ),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: _accent, width: 3),
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// RESULTS CARD
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.07),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: _buildResultsBody(),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsBody() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: CircularProgressIndicator(color: _accent),
        ),
      );
    }

    if (_error != null) {
      return Text(
        _error!,
        style: const TextStyle(color: Colors.red, fontSize: 14),
      );
    }

    final results = _results;
    if (results == null) {
      return Text(
        "Results will appear here",
        style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
      );
    }

    if (results.isEmpty) {
      return Text(
        'No stock found for "$_searchedFor"',
        style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$_totalUnits units across ${results.length} location${results.length == 1 ? '' : 's'}",
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        const SizedBox(height: 14),
        for (var i = 0; i < results.length; i++) ...[
          if (i > 0)
            Divider(height: 20, color: Colors.grey.shade100),
          _resultRow(results[i]),
        ],
      ],
    );
  }

  Widget _resultRow(StockLookupResultModel result) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.location_on_outlined,
              color: _accent, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            result.location.isNotEmpty ? result.location : "Unspecified",
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            "${result.totalCount}",
            style: const TextStyle(
              color: _accent,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
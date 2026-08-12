import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../models/location_model.dart';
import '../../services/locate_service.dart';
import '../../services/zebra_scan_service.dart';
import '../../utils/scanner_beep.dart';

class LocateStockScreen extends StatefulWidget {
  const LocateStockScreen({super.key});

  @override
  State<LocateStockScreen> createState() => _LocateStockScreenState();
}

class _RecentScan {
  final String code;
  final bool success;
  final String message;

  _RecentScan(
      {required this.code, required this.success, required this.message});
}

class _LocateStockScreenState extends State<LocateStockScreen> {
  static const _accent = Color(0xFF5C6BC0);

  final MobileScannerController _controller =
      MobileScannerController(facing: CameraFacing.front);
  final LocateService _service = LocateService();
  final TextEditingController _manualController = TextEditingController();

  late Future<List<LocationModel>> _locationsFuture;
  List<LocationModel> _locations = [];
  LocationModel? _selectedLocation;

  final List<_RecentScan> _recentScans = [];
  bool _isProcessing = false;
  DateTime? _lastScanTime;
  StreamSubscription<String>? _zebraSub;

  @override
  void initState() {
    super.initState();
    _locationsFuture = _service.fetchLocations();
    // Zebra hardware trigger scans (via DataWedge) feed the same handler
    // as the camera preview below.
    _zebraSub = ZebraScanService.instance.onScan.listen(_handleScan);
  }

  Future<void> _handleScan(String code) async {
    if (_isProcessing) return;
    final now = DateTime.now();
    if (_lastScanTime != null &&
        now.difference(_lastScanTime!) < const Duration(seconds: 1)) {
      return;
    }
    _lastScanTime = now;

    if (_selectedLocation == null) {
      _showSnack("Locations still loading, try again", Colors.orange);
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _isProcessing = true);

    final result = await _service.scan(
      uid: code,
      location: _selectedLocation!.location,
    );

    if (!mounted) return;
    setState(() {
      _isProcessing = false;
      _recentScans.insert(
        0,
        _RecentScan(
            code: code, success: result.success, message: result.message),
      );
    });

    _showSnack(result.message, result.success ? Colors.green : Colors.red);
  }

  void _showSnack(String msg, Color color) {
    if (color == Colors.red) ScannerBeep.playError();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openManualEntry() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Enter Barcode"),
        content: TextField(
          controller: _manualController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: "Enter code",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _accent),
            onPressed: () {
              final code = _manualController.text.trim();
              if (code.isNotEmpty) {
                Navigator.pop(context);
                _manualController.clear();
                _handleScan(code);
              }
            },
            child: const Text("Confirm", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _zebraSub?.cancel();
    _controller.dispose();
    _manualController.dispose();
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
          "Locate Stock",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: _openManualEntry),
        ],
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
                  colors: [Color(0xFF5C6BC0), Color(0xFF7E8CE0)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(35)),
              ),
              child: Column(
                children: [
                  const Text(
                    "Move stock to a location",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<List<LocationModel>>(
                    future: _locationsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Text(
                          "Failed to load locations",
                          style: TextStyle(color: Colors.red.shade100),
                        );
                      }
                      if (!snapshot.hasData) {
                        return const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        );
                      }

                      _locations = snapshot.data!;
                      if (_locations.isNotEmpty) {
                        _selectedLocation ??= _locations.first;
                      }

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<LocationModel>(
                            value: _selectedLocation,
                            isExpanded: true,
                            items: _locations.map((e) {
                              return DropdownMenuItem(
                                value: e,
                                child: Text(e.location),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => _selectedLocation = value);
                            },
                          ),
                        ),
                      );
                    },
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
                    if (_isProcessing)
                      Container(
                        color: Colors.black26,
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// RECENT SCANS CARD
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Recent scans (${_recentScans.length})",
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    const SizedBox(height: 14),
                    if (_recentScans.isEmpty)
                      Text(
                        "Scan a barcode to move it to the selected location",
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                      )
                    else
                      for (var i = 0; i < _recentScans.length; i++) ...[
                        if (i > 0) Divider(height: 20, color: Colors.grey.shade100),
                        _scanRow(_recentScans[i]),
                      ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _scanRow(_RecentScan scan) {
    return Row(
      children: [
        Icon(
          scan.success ? Icons.check_circle : Icons.error,
          color: scan.success ? Colors.green : Colors.red,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                scan.code,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                scan.message,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
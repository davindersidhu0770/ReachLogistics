import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../services/scan_service.dart';
import '../../utils/scanner_beep.dart';

class QRScannerScreen extends StatefulWidget {
  final String containerId;
  final String itemId;
  final String itemName;
  final String location;
  final int conditionId;
  final int requiredQty;

  const QRScannerScreen({
    super.key,
    required this.containerId,
    required this.itemId,
    required this.itemName,
    required this.location,
    required this.conditionId,
    required this.requiredQty,
  });

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    formats: [BarcodeFormat.all],
    detectionSpeed: DetectionSpeed.unrestricted,
    facing: CameraFacing.front,
  );
  final ScanService _scanService = ScanService();
  final TextEditingController _manualController = TextEditingController();

  String? _scannedUid;
  String? _scannedSerial;
  bool _isProcessing = false;
  DateTime? _lastScanTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _controller.start());
  }

  bool get _readyToSubmit => _scannedUid != null && _scannedSerial != null;

  /// Step label shown in header
  String get _stepLabel {
    if (_scannedUid == null) return "Step 1: Scan UID";
    if (_scannedSerial == null) return "Step 2: Scan Serial Number";
    return "Review & Submit";
  }

  /// =========================
  /// HANDLE SCAN
  /// =========================
  void _handleScan(String code) {
    if (_readyToSubmit) return;

    if (_lastScanTime != null &&
        DateTime.now().difference(_lastScanTime!) <
            const Duration(seconds: 2)) {
      return;
    }
    _lastScanTime = DateTime.now();

    HapticFeedback.mediumImpact();

    if (_scannedUid == null) {
      setState(() => _scannedUid = code);
      _showSnack("UID captured. Now scan Serial Number", Colors.blue);
    } else if (_scannedSerial == null) {
      if (code == _scannedUid) return; // prevent same code captured as serial
      setState(() => _scannedSerial = code);
      _controller.stop(); // both codes captured — release camera
      _showSnack("Serial captured. Review and submit", Colors.green);
    }
  }

  /// =========================
  /// SUBMIT
  /// =========================
  Future<void> _submit() async {
    if (!_readyToSubmit || _isProcessing) return;

    setState(() => _isProcessing = true);

    final error = await _scanService.sendPairedScan(
        uid: _scannedUid!,
        serialNumber: _scannedSerial!,
        location: widget.location,
        conditionId: widget.conditionId);

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (error == null) {
      Navigator.pop(context, true);
    } else {
      _showSnack(error, Colors.red);
      _reset();
    }
  }

  /// =========================
  /// RESET
  /// =========================
  void _reset() {
    setState(() {
      _scannedUid = null;
      _scannedSerial = null;
    });
    _lastScanTime = null;
    _controller.start(); // restart camera for re-scanning after error
  }

  /// =========================
  /// MANUAL ENTRY
  /// =========================
  void _openManualEntry() {
    final isUidStep = _scannedUid == null;
    final label = isUidStep ? "Enter UID" : "Enter Serial Number";

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(label),
        content: TextField(
          controller: _manualController,
          decoration: InputDecoration(
            hintText: label,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4D2D),
            ),
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

  void _showSnack(String msg, Color color) {
    if (color == Colors.red) ScannerBeep.playError();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(msg),
          backgroundColor: color,
          duration: const Duration(seconds: 2)),
    );
  }

  @override
  void dispose() {
    _controller.stop();
    _controller.dispose();
    _manualController.dispose();
    super.dispose();
  }

  /// =========================
  /// UI
  /// =========================
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    // Restrict detection to the visible preview box only.
    // Prevents the large carton barcode outside the frame from being picked up
    // and focuses the decoder on the exact 220px area the user is aiming at.
    final scanWindow = Rect.fromLTWH(
      0,
      0,
      MediaQuery.of(context).size.width - 40, // 20px margin each side
      220,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.itemName,
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (!_readyToSubmit)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _openManualEntry,
            ),
        ],
      ),

      /// SUBMIT pinned at bottom — never cut off
      bottomNavigationBar: _readyToSubmit
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      elevation: 6,
                      backgroundColor: const Color(0xFFFF4D2D),
                      shadowColor: const Color(0xFFFF4D2D).withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: _isProcessing
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Submit",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            )
          : null,

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
                  colors: [Color(0xFFFF4D2D), Color(0xFFFF7A59)],
                ),
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(35)),
              ),
              child: Column(
                children: [
                  const Text(
                    "Scanning Item",
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _stepLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// SCANNER — hide once both codes are captured
            if (!_readyToSubmit)
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
                          border: Border.all(
                              color: const Color(0xFFFF4D2D), width: 3),
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 20),

            /// SCANNED VALUES CARD
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
                    const Text(
                      "Captured Values",
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    const SizedBox(height: 16),
                    _valueRow(
                      label: "UID",
                      value: _scannedUid,
                      isDone: _scannedUid != null,
                      onClear: _scannedUid != null ? _reset : null,
                    ),
                    const Divider(height: 24),
                    _valueRow(
                      label: "Serial Number",
                      value: _scannedSerial,
                      isDone: _scannedSerial != null,
                      onClear: _scannedSerial != null
                          ? () => setState(() => _scannedSerial = null)
                          : null,
                    ),
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

  Widget _valueRow({
    required String label,
    required String? value,
    required bool isDone,
    VoidCallback? onClear,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isDone
                ? Colors.green.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isDone ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isDone ? Colors.green : Colors.grey,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 2),
              Text(
                value ?? "Waiting...",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDone ? Colors.black87 : Colors.grey,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (isDone && onClear != null)
          GestureDetector(
            onTap: onClear,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.delete_outline,
                  color: Colors.red.shade400, size: 20),
            ),
          ),
      ],
    );
  }
}

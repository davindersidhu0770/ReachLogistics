import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/picking_scan_result.dart';
import '../../services/picking_service.dart';
import '../../services/zebra_scan_service.dart';
import '../../utils/scanner_beep.dart';
import '../../widgets/fullscreen_camera_scan.dart';

class PickingScannerScreen extends StatefulWidget {
  final int orderItemId;
  final String itemName;
  final int requiredQty;

  const PickingScannerScreen({
    super.key,
    required this.orderItemId,
    required this.itemName,
    required this.requiredQty,
  });

  @override
  State<PickingScannerScreen> createState() => _PickingScannerScreenState();
}

class _PickingScannerScreenState extends State<PickingScannerScreen> {
  final PickingService _service = PickingService();
  final TextEditingController _manualController = TextEditingController();

  bool _isProcessing = false;
  bool _waitingForBulkScan = false;
  bool _orderItemVerified = false;
  DateTime? _lastScanTime;
  StreamSubscription<String>? _zebraSub;

  @override
  void initState() {
    super.initState();
    // Zebra hardware trigger scans (via DataWedge) feed the same handler
    // as the camera preview below.
    _zebraSub = ZebraScanService.instance.onScan.listen(_handleScan);
  }

  Future<void> _handleScan(String scannedCode) async {
    if (_isProcessing) return;
    if (_lastScanTime != null &&
        DateTime.now().difference(_lastScanTime!) < const Duration(seconds: 1)) {
      return;
    }
    _lastScanTime = DateTime.now();

    HapticFeedback.mediumImpact();

    // ── STEP 1: Verify order item locally then call API ───────────────────
    if (!_orderItemVerified) {
      final scannedId = int.tryParse(scannedCode);

      if (scannedId == null || scannedId != widget.orderItemId) {
        _showSnack(
          "Wrong item scanned. Expected: ${widget.orderItemId}",
          Colors.red,
        );
        return;
      }

      setState(() {
        _isProcessing = true;
        _orderItemVerified = true;
      });

      final result = await _service.scanFirst(widget.orderItemId);

      if (!mounted) return;
      setState(() => _isProcessing = false);

      _showSnack(result.message, result.success ? Colors.green : Colors.red);

      if (!result.success) {
        setState(() => _orderItemVerified = false);
        return;
      }

      if (result.isCompleted) {
        Navigator.pop(context, true);
        return;
      }

      if (result.isBulk) {
        setState(() => _waitingForBulkScan = true);
      }

      return;
    }

    // ── STEP 2: Bulk second scan (uid) ────────────────────────────────────
    setState(() => _isProcessing = true);

    final result = await _service.scanSecond(widget.orderItemId, scannedCode);

    if (!mounted) return;
    setState(() => _isProcessing = false);

    _showSnack(result.message, result.success ? Colors.green : Colors.red);

    if (!result.success) return;

    if (result.isCompleted) {
      Navigator.pop(context, true);
    }
  }

  void _openManualEntry() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          !_orderItemVerified
              ? "Enter Order Item ID"
              : _waitingForBulkScan
              ? "Enter Second Item UID"
              : "Enter UID",
        ),
        content: TextField(
          controller: _manualController,
          autofocus: true,
          keyboardType: !_orderItemVerified
              ? TextInputType.number
              : TextInputType.text,
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
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
            ),
            onPressed: () {
              final code = _manualController.text.trim();
              if (code.isNotEmpty) {
                Navigator.pop(context);
                _manualController.clear();
                _handleScan(code);
              }
            },
            child: const Text("Submit", style: TextStyle(color: Colors.white)),
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
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _zebraSub?.cancel();
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

    final accent = _waitingForBulkScan
        ? const Color(0xFF6A1B9A)
        : const Color(0xFF1565C0);

    final int step = !_orderItemVerified ? 1 : _waitingForBulkScan ? 3 : 2;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── CAMERA (off by default — Zebra hardware trigger scans work
          // without it; tap "Open Camera" for an on-screen fallback) ──────
          FullscreenCameraScan(
            onDetect: _handleScan,
            accent: accent,
          ),

          // ── TOP BAR ─────────────────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        widget.itemName,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(blurRadius: 8, color: Colors.black54),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white),
                      onPressed: _openManualEntry,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── BOTTOM PANEL ────────────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.85),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _StepIndicator(step: step, accent: accent),

                  const SizedBox(height: 18),

                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      !_orderItemVerified
                          ? "Scan Order Item"
                          : _waitingForBulkScan
                          ? "Scan Second Item"
                          : "Scan Item",
                      key: ValueKey('$_orderItemVerified-$_waitingForBulkScan'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(blurRadius: 8, color: Colors.black)],
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    !_orderItemVerified
                        ? "Point camera at order item barcode"
                        : _waitingForBulkScan
                        ? "Bulk Item — Step 2 of 2"
                        : "Point camera at barcode",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.65),
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 20),

                  if (_isProcessing)
                    const CircularProgressIndicator(color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

}

// ── Step Indicator ───────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int step; // 1 = scan order item, 2 = item verified, 3 = bulk second scan
  final Color accent;

  const _StepIndicator({required this.step, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _dot(active: step >= 1, done: step > 1, accent: accent, label: "Order"),
        _line(filled: step > 1, accent: accent),
        _dot(active: step >= 2, done: step > 2, accent: accent, label: "Scan"),
        _line(filled: step > 2, accent: accent),
        _dot(active: step >= 3, done: false, accent: accent, label: "Bulk"),
      ],
    );
  }

  Widget _dot({
    required bool active,
    required bool done,
    required Color accent,
    required String label,
  }) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: active ? accent : Colors.white24,
            shape: BoxShape.circle,
          ),
          child: Icon(
            done ? Icons.check : Icons.circle,
            color: Colors.white,
            size: done ? 16 : 8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: active ? Colors.white : Colors.white38,
          ),
        ),
      ],
    );
  }

  Widget _line({required bool filled, required Color accent}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 40,
        height: 2,
        color: filled ? accent : Colors.white24,
      ),
    );
  }
}

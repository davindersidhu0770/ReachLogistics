import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/order_item_model.dart';
import '../../services/van_loading_service.dart';
import '../../services/zebra_scan_service.dart';
import '../../utils/scanner_beep.dart';
import '../../widgets/fullscreen_camera_scan.dart';

class VanLoadingScannerScreen extends StatefulWidget {
  final List<OrderItemModel> items;

  const VanLoadingScannerScreen({super.key, required this.items});

  @override
  State<VanLoadingScannerScreen> createState() =>
      _VanLoadingScannerScreenState();
}

class _VanLoadingScannerScreenState extends State<VanLoadingScannerScreen> {
  final VanLoadingService _service = VanLoadingService();
  final TextEditingController _manualController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Set<int> _doneIds = {};
  OrderItemModel? _activeItem;
  bool _isProcessing = false;
  bool _allDone = false;
  String? _statusMsg;
  bool _statusIsError = false;
  DateTime? _lastScanTime;
  StreamSubscription<String>? _zebraSub;

  static const _accent = Color(0xFF00695C);

  @override
  void initState() {
    super.initState();
    // Zebra hardware trigger scans (via DataWedge) feed the same handler
    // as the camera preview below.
    _zebraSub = ZebraScanService.instance.onScan.listen(_handleScan);
  }

  // ── Scan handler ─────────────────────────────────────────────────────────

  Future<void> _handleScan(String code) async {
    if (_isProcessing || _allDone) return;
    final now = DateTime.now();
    if (_lastScanTime != null &&
        now.difference(_lastScanTime!) < const Duration(milliseconds: 1200)) {
      return;
    }
    _lastScanTime = now;
    HapticFeedback.mediumImpact();

    final scannedId = int.tryParse(code);
    if (scannedId == null) {
      _setStatus("Invalid barcode", error: true);
      return;
    }

    if (_doneIds.contains(scannedId)) {
      _setStatus("Already loaded", error: true);
      return;
    }

    final item = widget.items.cast<OrderItemModel?>().firstWhere(
      (i) => i!.orderItemId == scannedId,
      orElse: () => null,
    );

    if (item == null) {
      _setStatus("Item not in this manifesto", error: true);
      return;
    }

    setState(() {
      _activeItem = item;
      _isProcessing = true;
      _statusMsg = null;
    });
    _scrollToItem(item);

    final result = await _service.scan(item.orderItemId);
    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (!result.success) {
      setState(() => _activeItem = null);
      _setStatus(result.message, error: true);
      return;
    }

    _markDone(item);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _markDone(OrderItemModel item) {
    HapticFeedback.heavyImpact();
    setState(() {
      _doneIds.add(item.orderItemId);
      _activeItem = null;
      _statusMsg = null;
      _statusIsError = false;
    });

    final remaining =
        widget.items.where((i) => !_doneIds.contains(i.orderItemId)).length;
    if (remaining == 0) {
      setState(() => _allDone = true);
    }
  }

  void _setStatus(String msg, {bool error = false}) {
    if (error) ScannerBeep.playError();
    setState(() {
      _statusMsg = msg;
      _statusIsError = error;
    });
  }

  void _scrollToItem(OrderItemModel item) {
    final index =
        widget.items.indexWhere((i) => i.orderItemId == item.orderItemId);
    if (index >= 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            index * 130.0,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  void _openManualEntry() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Enter Item Barcode"),
        content: TextField(
          controller: _manualController,
          autofocus: true,
          keyboardType: TextInputType.number,
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
            child: const Text("Submit", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _zebraSub?.cancel();
    _manualController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    final done = _doneIds.length;
    final total = widget.items.length;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Camera (off by default — Zebra hardware trigger scans work
          // without it; tap "Open Camera" for an on-screen fallback) ──────
          if (!_allDone)
            FullscreenCameraScan(
              onDetect: _handleScan,
              accent: _accent,
            ),

          // ── All done overlay ───────────────────────────────────────────
          if (_allDone) _buildAllDoneOverlay(total),

          // ── Top bar ────────────────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white),
                      onPressed: () =>
                          Navigator.pop(context, _doneIds.isNotEmpty),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            "$done / $total items loaded",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(blurRadius: 8, color: Colors.black54)
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: total > 0 ? done / total : 0,
                              backgroundColor: Colors.white24,
                              valueColor:
                                  const AlwaysStoppedAnimation<Color>(_accent),
                              minHeight: 5,
                            ),
                          ),
                        ],
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

          // ── Bottom panel ───────────────────────────────────────────────
          if (!_allDone)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.92),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Status area
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 14),
                      child: Column(
                        children: [
                          // Active item info
                          if (_activeItem != null) ...[
                            Text(
                              _activeItem!.productCode,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(blurRadius: 6, color: Colors.black)
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.location_on,
                                    color: Colors.white54, size: 13),
                                const SizedBox(width: 3),
                                Text(
                                  _activeItem!.location.isNotEmpty
                                      ? _activeItem!.location
                                      : "No location",
                                  style: const TextStyle(
                                      color: Colors.white54, fontSize: 13),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                          ],

                          // Status text
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: _isProcessing
                                ? const SizedBox(
                                    width: 26,
                                    height: 26,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2.5),
                                  )
                                : Text(
                                    _buildStatusText(),
                                    key: ValueKey(
                                        '$_statusMsg${_activeItem?.orderItemId}'),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: _statusIsError
                                          ? Colors.redAccent
                                          : Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),

                    // Mini items list
                    SizedBox(
                      height: 88,
                      child: ListView.builder(
                        controller: _scrollController,
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                        itemCount: widget.items.length,
                        itemBuilder: (context, index) {
                          final item = widget.items[index];
                          final isDone = _doneIds.contains(item.orderItemId);
                          final isActive =
                              _activeItem?.orderItemId == item.orderItemId;

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 120,
                            margin: const EdgeInsets.only(right: 10),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: isDone
                                  ? Colors.green.withValues(alpha: 0.2)
                                  : isActive
                                      ? _accent.withValues(alpha: 0.3)
                                      : Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isDone
                                    ? Colors.green
                                    : isActive
                                        ? _accent
                                        : Colors.white24,
                                width: isActive ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.productCode.isNotEmpty
                                            ? item.productCode
                                            : "#${item.orderItemId}",
                                        style: TextStyle(
                                          color: isDone
                                              ? Colors.greenAccent
                                              : Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (isDone)
                                      const Icon(Icons.check_circle,
                                          color: Colors.greenAccent, size: 13),
                                  ],
                                ),
                                Text(
                                  item.location.isNotEmpty
                                      ? item.location
                                      : "—",
                                  style: const TextStyle(
                                      color: Colors.white38, fontSize: 11),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _buildStatusText() {
    if (_statusMsg != null) return _statusMsg!;
    if (_activeItem != null) return "Item found";
    return "Scan any item";
  }

  Widget _buildAllDoneOverlay(int total) {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.5, end: 1.0),
              duration: const Duration(milliseconds: 500),
              curve: Curves.elasticOut,
              builder: (_, v, child) =>
                  Transform.scale(scale: v, child: child),
              child: const Icon(Icons.check_circle,
                  color: Colors.greenAccent, size: 90),
            ),
            const SizedBox(height: 20),
            const Text(
              "Van Loaded!",
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "$total of $total items loaded",
              style: const TextStyle(color: Colors.white54, fontSize: 16),
            ),
            const SizedBox(height: 36),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                padding: const EdgeInsets.symmetric(
                    horizontal: 48, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                "Done",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
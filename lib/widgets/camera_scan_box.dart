import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Optional on-screen camera for the "card" style scanner screens (Stock
/// Lookup, Locate Stock, Change Stock Condition, QR Scanner).
///
/// The camera is OFF by default — these screens scan out of the box via the
/// Zebra hardware trigger (see ZebraScanService), which is independent of
/// this widget. Tapping "Open Camera" starts an on-screen camera fallback
/// with a front/back switch button. Size it by placing it inside a
/// fixed-height Container/SizedBox, as with the previous inline MobileScanner.
class CameraScanBox extends StatefulWidget {
  final void Function(String code) onDetect;
  final Color accent;
  final bool preferFrontCamera;
  final double boxHeight;

  const CameraScanBox({
    super.key,
    required this.onDetect,
    required this.accent,
    this.preferFrontCamera = false,
    this.boxHeight = 220,
  });

  @override
  State<CameraScanBox> createState() => _CameraScanBoxState();
}

class _CameraScanBoxState extends State<CameraScanBox> {
  MobileScannerController? _controller;
  bool _cameraOpen = false;

  void _openCamera() {
    final controller = MobileScannerController(
      facing: widget.preferFrontCamera ? CameraFacing.front : CameraFacing.back,
      autoStart: false,
    );
    setState(() {
      _controller = controller;
      _cameraOpen = true;
    });
    controller.start();
  }

  void _closeCamera() {
    final controller = _controller;
    setState(() {
      _cameraOpen = false;
      _controller = null;
    });
    controller?.stop();
    controller?.dispose();
  }

  void _flipCamera() => _controller?.switchCamera();

  @override
  void dispose() {
    _controller?.stop();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.boxHeight,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: _cameraOpen ? _buildCamera(context) : _buildPlaceholder(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: widget.accent.withOpacity(0.25), width: 2),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.qr_code_scanner, color: widget.accent, size: 34),
            const SizedBox(height: 8),
            Text(
              "Zebra scanner ready",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              "Pull the trigger to scan",
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _openCamera,
              icon: const Icon(Icons.camera_alt, size: 18),
              label: const Text("Open Camera"),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCamera(BuildContext context) {
    final scanWindow = Rect.fromLTWH(
      0,
      0,
      MediaQuery.of(context).size.width - 40,
      widget.boxHeight,
    );

    return Stack(
      children: [
        MobileScanner(
          controller: _controller,
          scanWindow: scanWindow,
          onDetect: (capture) {
            if (capture.barcodes.isEmpty) return;
            final code = capture.barcodes.first.rawValue;
            if (code != null) widget.onDetect(code);
          },
        ),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: widget.accent, width: 3),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Row(
            children: [
              _roundIconButton(Icons.cameraswitch, _flipCamera),
              const SizedBox(width: 8),
              _roundIconButton(Icons.close, _closeCamera),
            ],
          ),
        ),
      ],
    );
  }

  Widget _roundIconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.45),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

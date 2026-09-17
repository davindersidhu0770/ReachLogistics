import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Optional on-screen camera for the full-screen dedicated scanner screens
/// (Picking, Batch Picking, Debriefing, Van Loading).
///
/// The camera is OFF by default — these screens scan out of the box via the
/// Zebra hardware trigger (see ZebraScanService), which is independent of
/// this widget. Tapping "Open Camera" starts an on-screen camera fallback
/// (with the same vignette/scan-frame look the screens used to render
/// permanently) plus a front/back switch button. Place it as a Positioned.fill
/// (or other expand-to-fill) child of the screen's Stack.
class FullscreenCameraScan extends StatefulWidget {
  final void Function(String code) onDetect;
  final Color accent;
  final bool preferFrontCamera;

  const FullscreenCameraScan({
    super.key,
    required this.onDetect,
    required this.accent,
    this.preferFrontCamera = false,
  });

  @override
  State<FullscreenCameraScan> createState() => _FullscreenCameraScanState();
}

class _FullscreenCameraScanState extends State<FullscreenCameraScan> {
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
    return _cameraOpen ? _buildCamera(context) : _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.qr_code_scanner, color: Colors.white54, size: 64),
            const SizedBox(height: 16),
            const Text(
              "Zebra scanner ready",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Pull the trigger to scan",
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _openCamera,
              icon: const Icon(Icons.camera_alt, size: 18),
              label: const Text("Open Camera"),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.accent,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCamera(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        MobileScanner(
          controller: _controller,
          onDetect: (capture) {
            final code = capture.barcodes.first.rawValue;
            if (code != null) widget.onDetect(code);
          },
        ),
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 0.85,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.55),
              ],
            ),
          ),
        ),
        Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              border: Border.all(color: widget.accent, width: 3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Stack(children: _corners(widget.accent)),
          ),
        ),
        Positioned(
          right: 12,
          top: MediaQuery.of(context).size.height / 2 - 56,
          child: Column(
            children: [
              _roundIconButton(Icons.cameraswitch, _flipCamera),
              const SizedBox(height: 10),
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
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  List<Widget> _corners(Color color) {
    const size = 22.0;
    const thick = 3.5;

    Widget corner(AlignmentGeometry alignment, bool flipX, bool flipY) {
      return Align(
        alignment: alignment,
        child: Transform.scale(
          scaleX: flipX ? -1 : 1,
          scaleY: flipY ? -1 : 1,
          child: SizedBox(
            width: size,
            height: size,
            child: CustomPaint(painter: _CornerPainter(color, thick)),
          ),
        ),
      );
    }

    return [
      corner(Alignment.topLeft, false, false),
      corner(Alignment.topRight, true, false),
      corner(Alignment.bottomLeft, false, true),
      corner(Alignment.bottomRight, true, true),
    ];
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  final double thick;

  _CornerPainter(this.color, this.thick);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thick
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(
      Path()
        ..moveTo(0, size.height)
        ..lineTo(0, 0)
        ..lineTo(size.width, 0),
      paint,
    );
  }

  @override
  bool shouldRepaint(_CornerPainter old) =>
      old.color != color || old.thick != thick;
}

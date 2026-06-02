import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import '../../models/confirm_order_questions_model.dart';
import '../../services/confirm_order_service.dart';

class ConfirmOrderQuestionsScreen extends StatefulWidget {
  final int orderId;
  final int orderItemId;
  final String description;
  final String personToDeliver;

  const ConfirmOrderQuestionsScreen({
    super.key,
    required this.orderId,
    required this.orderItemId,
    required this.description,
    required this.personToDeliver,
  });

  @override
  State<ConfirmOrderQuestionsScreen> createState() =>
      _ConfirmOrderQuestionsScreenState();
}

class _ConfirmOrderQuestionsScreenState
    extends State<ConfirmOrderQuestionsScreen> {
  final _service = ConfirmOrderService();

  ConfirmOrderQuestionsData? _data;
  bool _loading = true;
  String? _loadError;
  final Map<int, bool?> _answers = {};

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      final data = await _service.fetchQuestions(widget.orderId);
      setState(() {
        _data = data;
        _loading = false;
        for (final q in data.questions) {
          _answers[q.questionId] = null;
        }
      });
    } catch (e) {
      setState(() {
        _loadError = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  void _validateAndSign() {
    final unanswered = _answers.values.any((v) => v == null);
    if (unanswered) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please answer all questions before submitting."),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    _openSignatureSheet();
  }

  void _openSignatureSheet() {
    final repaintKey = GlobalKey();
    final canvasKey = GlobalKey<_SignatureCanvasState>();
    bool hasSignature = false;
    bool submitting = false;

    final answers = _answers.entries
        .map((e) => {
              'questionId': e.key,
              'isAnsweredYes': e.value!,
              'answerText': '',
            })
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            Future<void> submit() async {
              if (!(canvasKey.currentState?.hasDrawn ?? false)) {
                showDialog(
                  context: ctx,
                  builder: (_) => AlertDialog(
                    title: const Text("Signature Required"),
                    content: const Text(
                        "Please draw your signature before submitting."),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text("OK"),
                      ),
                    ],
                  ),
                );
                return;
              }

              setSheetState(() => submitting = true);

              try {
                final ro =
                    repaintKey.currentContext?.findRenderObject();
                if (ro == null || ro is! RenderRepaintBoundary) {
                  throw Exception(
                      "Could not capture signature. Please try again.");
                }
                final image = await ro.toImage(pixelRatio: 2.0);
                final byteData = await image.toByteData(
                    format: ui.ImageByteFormat.png);
                if (byteData == null) {
                  throw Exception("Signature export failed.");
                }
                final base64Sig =
                    base64Encode(byteData.buffer.asUint8List());

                final result = await _service.saveConfirmation(
                  orderId: widget.orderId,
                  disclaimerAccepted: true,
                  signatureBase64: base64Sig,
                  answers: answers,
                );

                if (ctx.mounted) Navigator.of(ctx).pop();
                if (!mounted) return;

                final success = result['success'] == true;
                final message = (result['message'] ??
                        (success ? 'Confirmation saved!' : 'Failed'))
                    .toString();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(message),
                    backgroundColor:
                        success ? const Color(0xFF6A1B9A) : Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );

                if (success) Navigator.of(context).pop(true);
              } catch (e) {
                setSheetState(() => submitting = false);
                if (ctx.mounted) {
                  showDialog(
                    context: ctx,
                    builder: (_) => AlertDialog(
                      title: const Text("Error"),
                      content: Text(
                          e.toString().replaceFirst('Exception: ', '')),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text("OK"),
                        ),
                      ],
                    ),
                  );
                }
              }
            }

            return SafeArea(
              child: Container(
                height: MediaQuery.of(ctx).size.height * 0.82,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 14),
                    Container(
                      width: 45,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Customer Signature",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          // Opacity keeps layout stable — no jump when it appears
                          Opacity(
                            opacity: hasSignature ? 1.0 : 0.0,
                            child: GestureDetector(
                              onTap: hasSignature
                                  ? () {
                                      canvasKey.currentState?.clear();
                                      setSheetState(
                                          () => hasSignature = false);
                                    }
                                  : null,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 7),
                                decoration: BoxDecoration(
                                  color: Colors.red
                                      .withValues(alpha: 0.1),
                                  borderRadius:
                                      BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.refresh,
                                        color: Colors.red, size: 16),
                                    SizedBox(width: 4),
                                    Text(
                                      "Clear",
                                      style: TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        "Draw your signature in the box below",
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade500),
                      ),
                    ),
                    const SizedBox(height: 14),

                    /// SIGNATURE CANVAS — isolated widget, only it repaints on draw
                    Expanded(
                      child: Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 20),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: hasSignature
                                  ? const Color(0xFF6A1B9A)
                                  : Colors.grey.shade300,
                              width: hasSignature ? 2 : 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    Colors.black.withValues(alpha: 0.05),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: _SignatureCanvas(
                              key: canvasKey,
                              repaintBoundaryKey: repaintKey,
                              onFirstStroke: () =>
                                  setSheetState(() => hasSignature = true),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: submitting
                                  ? null
                                  : () => Navigator.pop(sheetContext),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                    color: Colors.grey.shade400),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(18)),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 16),
                              ),
                              child: const Text(
                                "Cancel",
                                style: TextStyle(
                                    color: Colors.black54,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: submitting ? null : submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6A1B9A),
                                disabledBackgroundColor:
                                    const Color(0xFF6A1B9A)
                                        .withValues(alpha: 0.5),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(18)),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 16),
                                elevation: 4,
                              ),
                              child: submitting
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2),
                                    )
                                  : const Text(
                                      "Confirm & Submit",
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
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
          "Order Confirmation",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
              top: 110,
              left: 20,
              right: 20,
              bottom: 28,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6A1B9A), Color(0xFFAB47BC)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.description.isNotEmpty)
                  Text(
                    widget.description,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                if (widget.personToDeliver.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.person_outline,
                          color: Colors.white70, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        widget.personToDeliver,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child:
                        CircularProgressIndicator(color: Color(0xFF6A1B9A)),
                  )
                : _loadError != null
                    ? Center(
                        child: Text(
                          "Error: $_loadError",
                          style: const TextStyle(color: Colors.red),
                        ),
                      )
                    : _buildForm(),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    final data = _data!;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (data.disclaimer.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF6A1B9A).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color:
                        const Color(0xFF6A1B9A).withValues(alpha: 0.25)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline,
                      color: Color(0xFF6A1B9A), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      data.disclaimer,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade800,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          const Text(
            "Questions",
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...data.questions.map((q) => _buildQuestionCard(q)),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 58,
            child: ElevatedButton(
              onPressed: _validateAndSign,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A1B9A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 4,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.draw_outlined, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "Submit Confirmation",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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

  Widget _buildQuestionCard(ConfirmOrderQuestion q) {
    final answer = _answers[q.questionId];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            q.question,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _answerButton(
                  label: "Yes",
                  selected: answer == true,
                  isYes: true,
                  onTap: () => setState(() => _answers[q.questionId] = true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _answerButton(
                  label: "No",
                  selected: answer == false,
                  isYes: false,
                  onTap: () =>
                      setState(() => _answers[q.questionId] = false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _answerButton({
    required String label,
    required bool selected,
    required bool isYes,
    required VoidCallback onTap,
  }) {
    final color = isYes ? Colors.green : Colors.red;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : color.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isYes ? Icons.check_circle_outline : Icons.cancel_outlined,
              color: selected ? Colors.white : color,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : color,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Signature Canvas ────────────────────────────────────────────────────────
// Isolated StatefulWidget so only the canvas repaints during drawing,
// not the entire bottom sheet.

class _SignatureCanvas extends StatefulWidget {
  final GlobalKey repaintBoundaryKey;
  final VoidCallback onFirstStroke;

  const _SignatureCanvas({
    super.key,
    required this.repaintBoundaryKey,
    required this.onFirstStroke,
  });

  @override
  State<_SignatureCanvas> createState() => _SignatureCanvasState();
}

class _SignatureCanvasState extends State<_SignatureCanvas> {
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];
  bool _hasDrawn = false;

  bool get hasDrawn => _hasDrawn;

  void clear() {
    setState(() {
      _strokes.clear();
      _currentStroke = [];
      _hasDrawn = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: widget.repaintBoundaryKey,
      child: Container(
        color: Colors.white,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (d) {
            final newStroke = [d.localPosition];
            setState(() {
              _strokes.add(newStroke);
              _currentStroke = newStroke;
              if (!_hasDrawn) {
                _hasDrawn = true;
                widget.onFirstStroke();
              }
            });
          },
          onPanUpdate: (d) {
            // Only this widget repaints — not the whole sheet
            setState(() => _currentStroke.add(d.localPosition));
          },
          onPanEnd: (_) {
            setState(() => _currentStroke = []);
          },
          child: CustomPaint(
            painter: _SignaturePainter(_strokes),
            child: SizedBox.expand(
              child: _hasDrawn
                  ? null
                  : Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.draw_outlined,
                              size: 44, color: Colors.grey.shade300),
                          const SizedBox(height: 8),
                          Text(
                            "Sign here",
                            style: TextStyle(
                                color: Colors.grey.shade400, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Signature Painter ───────────────────────────────────────────────────────
// Uses quadratic bezier curves through midpoints for smooth lines.

class _SignaturePainter extends CustomPainter {
  final List<List<Offset>> strokes;

  _SignaturePainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1A1A2E)
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.isEmpty) continue;

      if (stroke.length == 1) {
        canvas.drawCircle(
            stroke[0], 1.5, paint..style = PaintingStyle.fill);
        paint.style = PaintingStyle.stroke;
        continue;
      }

      final path = Path()..moveTo(stroke[0].dx, stroke[0].dy);

      if (stroke.length == 2) {
        path.lineTo(stroke[1].dx, stroke[1].dy);
      } else {
        // Smooth bezier: draw through midpoints between consecutive points
        for (int i = 0; i < stroke.length - 1; i++) {
          final mid = Offset(
            (stroke[i].dx + stroke[i + 1].dx) / 2,
            (stroke[i].dy + stroke[i + 1].dy) / 2,
          );
          if (i == 0) {
            path.lineTo(mid.dx, mid.dy);
          } else {
            path.quadraticBezierTo(
                stroke[i].dx, stroke[i].dy, mid.dx, mid.dy);
          }
        }
        path.lineTo(stroke.last.dx, stroke.last.dy);
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter old) => true;
}

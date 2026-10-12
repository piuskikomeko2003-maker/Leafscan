import 'dart:io';
import 'package:flutter/material.dart';
import '../models/detector.dart';
import '../models/disease_info.dart';

/// Shows a photo with the model's bounding boxes drawn on top.
class DetectionImage extends StatefulWidget {
  final File file;
  final List<Detection> detections;
  final BorderRadius borderRadius;

  const DetectionImage({
    super.key,
    required this.file,
    required this.detections,
    this.borderRadius = const BorderRadius.all(Radius.circular(14)),
  });

  @override
  State<DetectionImage> createState() => _DetectionImageState();
}

class _DetectionImageState extends State<DetectionImage> {
  ImageStream? _stream;
  ImageStreamListener? _listener;
  double? _aspectRatio;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  void _resolve() {
    final provider = FileImage(widget.file);
    final stream = provider.resolve(createLocalImageConfiguration(context));
    if (stream.key == _stream?.key) return;
    _stream?.removeListener(_listener!);
    _listener = ImageStreamListener((info, _) {
      if (!mounted) return;
      final r = info.image.width / info.image.height;
      if (_aspectRatio != r) setState(() => _aspectRatio = r);
    });
    stream.addListener(_listener!);
    _stream = stream;
  }

  @override
  void dispose() {
    if (_listener != null) _stream?.removeListener(_listener!);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: Center(
        child: AspectRatio(
          aspectRatio: _aspectRatio ?? 1.0,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.file(widget.file, fit: BoxFit.fill),
              if (widget.detections.isNotEmpty)
                CustomPaint(painter: _BoxPainter(widget.detections)),
            ],
          ),
        ),
      ),
    );
  }
}

class _BoxPainter extends CustomPainter {
  final List<Detection> detections;
  _BoxPainter(this.detections);

  static const Map<String, Color> _typeColors = {
    'fungal': Color(0xFF0B8379),
    'bacterial': Color(0xFF1565C0),
    'viral': Color(0xFF6A1B9A),
    'pest': Color(0xFFE65100),
    'none': Color(0xFF2E7D32),
    'unclear': Color(0xFF546E7A),
  };

  Color _colorFor(String label) {
    final type = kDiseaseDb[label]?.type ?? 'unclear';
    return _typeColors[type] ?? const Color(0xFF0B8379);
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final d in detections) {
      final color = _colorFor(d.label);
      final rect = Rect.fromLTRB(
        d.bbox[0] * size.width,
        d.bbox[1] * size.height,
        d.bbox[2] * size.width,
        d.bbox[3] * size.height,
      );

      final fill = Paint()
        ..style = PaintingStyle.fill
        ..color = color.withValues(alpha: 0.12);
      canvas.drawRect(rect, fill);

      final stroke = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = color;
      canvas.drawRect(rect, stroke);

      final label =
          '${d.label}  ${(d.confidence * 100).toStringAsFixed(0)}%';
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: size.width);

      const pad = EdgeInsets.symmetric(horizontal: 6, vertical: 3);
      final tagW = tp.width + pad.horizontal;
      final tagH = tp.height + pad.vertical;
      final above = rect.top - tagH >= 0;
      final tagTop = above ? rect.top - tagH : rect.top;
      final tagRect = Rect.fromLTWH(rect.left, tagTop, tagW, tagH);

      canvas.drawRRect(
        RRect.fromRectAndRadius(tagRect, const Radius.circular(4)),
        Paint()..color = color,
      );
      tp.paint(canvas, Offset(tagRect.left + pad.left, tagRect.top + pad.top));
    }
  }

  @override
  bool shouldRepaint(_BoxPainter old) => old.detections != detections;
}

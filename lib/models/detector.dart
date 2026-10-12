// lib/models/detector.dart
import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class Detection {
  final String rawLabel;   // exact label from the model
  final String label;      // cleaned display name
  final double confidence;
  final List<double> bbox; // x1,y1,x2,y2 normalized 0..1
  Detection(this.rawLabel, this.label, this.confidence, this.bbox);
}

class TomatoDetector {
  // MUST match class_names.json in order and spelling exactly.
  static const List<String> _rawLabels = [
    'Aphids',
    'Early Blight',
    'Healthy Leaf-',
    'Leaf Curl',
    'Leafhoppers and Jassids',
    'Molds',
    'Mosaic Virus',
    'Septoria',
    'bactarial canker',
    'bacterial spot',
    'flea beetle',
    'late_blight',
    'leafminer',
    'powedry_mildew',
    'yellow curl virus',
  ];

  // Raw -> clean display name (also the kDiseaseDb lookup key)
  static const Map<String, String> _labelMap = {
    'Aphids':                  'Aphids',
    'Early Blight':            'Early Blight',
    'Healthy Leaf-':           'Healthy Leaf',
    'Leaf Curl':               'Leaf Curl',
    'Leafhoppers and Jassids': 'Leafhoppers and Jassids',
    'Molds':                   'Molds',
    'Mosaic Virus':            'Mosaic Virus',
    'Septoria':                'Septoria',
    'bactarial canker':        'Bacterial Canker',
    'bacterial spot':          'Bacterial Spot',
    'flea beetle':             'Flea Beetle',
    'late_blight':             'Late Blight',
    'leafminer':               'Leafminer',
    'powedry_mildew':          'Powdery Mildew',
    'yellow curl virus':       'Yellow Curl Virus',
  };

  static String cleanLabel(String raw) => _labelMap[raw] ?? raw;

  static const double _confThreshold = 0.25;
  static const double _iouThreshold = 0.45;

  Interpreter? _interpreter;
  bool get isReady => _interpreter != null;

  // Resolved from the model at load time so we work with both the INT8
  // quantized export and a float32 export.
  TensorType _inType = TensorType.float32;
  TensorType _outType = TensorType.float32;
  double _inScale = 1;
  int _inZero = 0;
  double _outScale = 1;
  int _outZero = 0;
  bool _inNCHW = false;
  int _inH = 640;
  int _inW = 640;
  List<int> _outShape = const [1, 19, 8400];
  bool _channelFirst = true; // output laid out [1, 4+nc, anchors]
  int _numClasses = 15;
  int _numAnchors = 8400;

  bool get _inQuantized =>
      _inType == TensorType.int8 || _inType == TensorType.uint8;
  bool get _outQuantized =>
      _outType == TensorType.int8 || _outType == TensorType.uint8;

  Future<void> load() async {
    final options = InterpreterOptions()..threads = 4;
    _interpreter = await Interpreter.fromAsset(
      'assets/models/best_int8.tflite',
      options: options,
    );
    _configure(_interpreter!);
  }

  void _configure(Interpreter interp) {
    final inT = interp.getInputTensor(0);
    final outT = interp.getOutputTensor(0);
    _inType = inT.type;
    _outType = outT.type;

    if (_inQuantized) {
      final p = inT.params;
      _inScale = p.scale;
      _inZero = p.zeroPoint;
    }
    if (_outQuantized) {
      final p = outT.params;
      _outScale = p.scale;
      _outZero = p.zeroPoint;
    }

    final inShape = inT.shape;
    if (inShape.length == 4) {
      if (inShape[1] == 3 && inShape[3] != 3) {
        _inNCHW = true;
        _inH = inShape[2];
        _inW = inShape[3];
      } else {
        _inNCHW = false;
        _inH = inShape[1];
        _inW = inShape[2];
      }
    }

    _outShape = outT.shape;
    if (_outShape.length >= 3) {
      final d1 = _outShape[_outShape.length - 2];
      final d2 = _outShape[_outShape.length - 1];
      _channelFirst = d1 < d2;
      final channels = _channelFirst ? d1 : d2;
      _numAnchors = _channelFirst ? d2 : d1;
      _numClasses = channels - 4;
    }
    if (_numClasses <= 0 || _numClasses > _rawLabels.length) {
      _numClasses = _rawLabels.length;
    }
  }

  Future<List<Detection>> detect(File file) async {
    final interp = _interpreter;
    if (interp == null) throw StateError('Model not loaded');

    final bytes = await file.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) throw const FormatException('Could not decode image');
    final resized = img.copyResize(decoded, width: _inW, height: _inH);

    final input = _buildInput(resized);
    final output = _zeros(_outShape);

    interp.run(input, output);

    final raw = (output as List)[0] as List;
    return _nms(_parse(raw));
  }

  /// Builds a nested input tensor matching the model's input type/layout.
  Object _buildInput(img.Image resized) {
    double norm(num v) => v / 255.0;
    num pack(double v) => _inQuantized ? _quantize(v) : v;

    if (_inNCHW) {
      return List.generate(
        1,
        (_) => List.generate(3, (c) => List.generate(
              _inH,
              (y) => List.generate(_inW, (x) {
                final p = resized.getPixel(x, y);
                final v = c == 0 ? p.r : (c == 1 ? p.g : p.b);
                return pack(norm(v));
              }),
            )),
      );
    }
    return List.generate(
      1,
      (_) => List.generate(
        _inH,
        (y) => List.generate(_inW, (x) {
          final p = resized.getPixel(x, y);
          return [
            pack(norm(p.r)),
            pack(norm(p.g)),
            pack(norm(p.b)),
          ];
        }),
      ),
    );
  }

  int _quantize(double v) {
    final s = _inScale == 0 ? 1.0 : _inScale;
    final q = (v / s).round() + _inZero;
    if (_inType == TensorType.uint8) return q.clamp(0, 255);
    return q.clamp(-128, 127);
  }

  Object _zeros(List<int> shape) {
    if (shape.length == 1) {
      return _outQuantized
          ? List<int>.filled(shape[0], 0)
          : List<double>.filled(shape[0], 0.0);
    }
    return List.generate(shape[0], (_) => _zeros(shape.sublist(1)));
  }

  /// Reads channel [channel] of anchor [anchor], dequantizing when needed.
  double _at(List raw, int channel, int anchor) {
    final num v = _channelFirst
        ? (raw[channel][anchor] as num)
        : (raw[anchor][channel] as num);
    if (_outQuantized) return (v - _outZero) * _outScale;
    return v.toDouble();
  }

  List<Detection> _parse(List raw) {
    final candidates = <Detection>[];
    for (int i = 0; i < _numAnchors; i++) {
      double bestConf = 0;
      int bestCls = -1;
      for (int c = 0; c < _numClasses; c++) {
        final v = _at(raw, 4 + c, i);
        if (v > bestConf) {
          bestConf = v;
          bestCls = c;
        }
      }
      if (bestConf < _confThreshold) continue;

      final cx = _at(raw, 0, i);
      final cy = _at(raw, 1, i);
      final w = _at(raw, 2, i);
      final h = _at(raw, 3, i);

      // Some exports normalize coords to 0..1; others emit pixels of 640.
      final normalized = max(max(cx, cy), max(w, h)) <= 2.0;
      final s = normalized ? 1.0 : 1.0 / _inW;
      final x1 = ((cx - w / 2) * s).clamp(0.0, 1.0);
      final y1 = ((cy - h / 2) * s).clamp(0.0, 1.0);
      final x2 = ((cx + w / 2) * s).clamp(0.0, 1.0);
      final y2 = ((cy + h / 2) * s).clamp(0.0, 1.0);

      final rawLabel = _rawLabels[bestCls];
      candidates.add(Detection(
        rawLabel,
        cleanLabel(rawLabel),
        bestConf,
        [x1, y1, x2, y2],
      ));
    }
    return candidates;
  }

  List<Detection> _nms(List<Detection> dets) {
    dets.sort((a, b) => b.confidence.compareTo(a.confidence));
    final kept = <Detection>[];
    for (final d in dets) {
      bool keep = true;
      for (final k in kept) {
        if (d.rawLabel == k.rawLabel &&
            _iou(d.bbox, k.bbox) > _iouThreshold) {
          keep = false;
          break;
        }
      }
      if (keep) kept.add(d);
    }
    return kept;
  }

  double _iou(List<double> a, List<double> b) {
    final x1 = max(a[0], b[0]);
    final y1 = max(a[1], b[1]);
    final x2 = min(a[2], b[2]);
    final y2 = min(a[3], b[3]);
    final inter = max(0.0, x2 - x1) * max(0.0, y2 - y1);
    final union =
        (a[2] - a[0]) * (a[3] - a[1]) + (b[2] - b[0]) * (b[3] - b[1]) - inter;
    return union <= 0 ? 0 : inter / union;
  }
}

// lib/main.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'models/detector.dart';
import 'models/disease_info.dart';
import 'services/chat.dart';
import 'widgets/detection_image.dart';

void main() {
  // Fonts are bundled in assets/google_fonts so the app works fully offline.
  GoogleFonts.config.allowRuntimeFetching = false;
  runApp(const LeafScanApp());
}

class LeafScanApp extends StatelessWidget {
  const LeafScanApp({super.key});
  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF0B8379));
    return MaterialApp(
      title: 'LeafScan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: scheme,
        useMaterial3: true,
        textTheme: GoogleFonts.dmSansTextTheme(),
        scaffoldBackgroundColor: const Color(0xFFF3FAF9),
      ),
      home: const RootPage(),
    );
  }
}

class RootPage extends StatefulWidget {
  const RootPage({super.key});
  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  static const List<String> _sampleAssets = [
    'assets/samples/sample1.jpg',
    'assets/samples/sample2.jpg',
    'assets/samples/sample3.jpg',
  ];

  int _page = 0; // 0 Home, 1 Scan, 2 Result, 3 Chat
  final TomatoDetector _detector = TomatoDetector();
  bool _modelReady = false;
  String? _modelError;
  List<String> _availableSamples = const [];

  File? _image;
  List<Detection>? _detections;
  DiseaseInfo? _info;
  double? _conf;

  @override
  void initState() {
    super.initState();
    _loadModel();
    _detectSamples();
  }

  Future<void> _loadModel() async {
    try {
      await _detector.load();
      if (mounted) setState(() => _modelReady = true);
    } catch (e) {
      if (mounted) setState(() => _modelError = e.toString());
    }
  }

  // Only surfaces the sample row when real sample images are bundled.
  Future<void> _detectSamples() async {
    final found = <String>[];
    for (final asset in _sampleAssets) {
      try {
        await rootBundle.load(asset);
        found.add(asset);
      } catch (_) {
        // Asset not bundled - skip it.
      }
    }
    if (mounted) setState(() => _availableSamples = found);
  }

  void _go(int p) {
    if (p == 2 && _info == null) p = 1;
    setState(() => _page = p);
  }

  Future<void> _pick(ImageSource src) async {
    try {
      final picked = await ImagePicker()
          .pickImage(source: src, imageQuality: 92, maxWidth: 1600);
      if (picked == null) return;
      setState(() {
        _image = File(picked.path);
        _detections = null;
        _info = null;
        _conf = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open picker: $e')),
        );
      }
    }
  }

  Future<void> _loadSample(String assetPath, String label) async {
    try {
      final data = await rootBundle.load(assetPath);
      final dir = Directory.systemTemp;
      final f = File('${dir.path}/leafscan_sample_$label.jpg');
      await f.writeAsBytes(data.buffer.asUint8List());
      setState(() {
        _image = f;
        _detections = null;
        _info = null;
        _conf = null;
      });
      await _scan();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sample not available: $e')),
        );
      }
    }
  }

  Future<void> _scan() async {
    if (_image == null || !_modelReady) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _ScanningDialog(),
    );
    try {
      final dets = await _detector.detect(_image!);
      Detection? top;
      for (final d in dets) {
        if (top == null || d.confidence > top.confidence) top = d;
      }
      if (mounted) Navigator.pop(context);
      setState(() {
        _detections = dets;
        if (top != null) {
          _conf = top.confidence * 100;
          _info = kDiseaseDb[top.label] ?? fallbackInfo(top.label);
        } else {
          _conf = 0;
          _info = kNoDetectionInfo;
        }
      });
      _go(2);
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scan error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final showNav = _page != 0;

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _page,
          children: [
            _HomePage(onStart: () => _go(1)),
            _ScanPage(
              image: _image,
              detections: _detections ?? const [],
              ready: _modelReady,
              error: _modelError,
              onPickCamera: () => _pick(ImageSource.camera),
              onPickGallery: () => _pick(ImageSource.gallery),
              onScan: _scan,
              samples: _availableSamples,
              onSampleTap: _loadSample,
            ),
            _ResultPage(
              info: _info,
              conf: _conf,
              image: _image,
              detections: _detections ?? const [],
              onChat: () => _go(3),
              onBack: () => _go(1),
            ),
            _ChatPage(
              info: _info,
              onBack: () => _go(_info != null ? 2 : 1),
            ),
          ],
        ),
      ),
      bottomNavigationBar: showNav
          ? NavigationBar(
              selectedIndex: _page.clamp(0, 3),
              onDestinationSelected: _go,
              destinations: const [
                NavigationDestination(
                    icon: Icon(Icons.home_outlined), label: 'Home'),
                NavigationDestination(
                    icon: Icon(Icons.camera_alt_outlined), label: 'Scan'),
                NavigationDestination(
                    icon: Icon(Icons.analytics_outlined), label: 'Analysis'),
                NavigationDestination(
                    icon: Icon(Icons.chat_bubble_outline), label: 'Assistant'),
              ],
            )
          : null,
    );
  }
}

// ================== HOME ==================
class _HomePage extends StatelessWidget {
  final VoidCallback onStart;
  const _HomePage({required this.onStart});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 40),
        const Icon(Icons.eco, size: 96, color: Color(0xFF0B8379)),
        const SizedBox(height: 20),
        Text('LeafScan',
            textAlign: TextAlign.center,
            style: GoogleFonts.bricolageGrotesque(
                fontSize: 44,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0A2A2A))),
        const SizedBox(height: 8),
        Text('AI leaf scanner for tomato plants',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 16)),
        const SizedBox(height: 40),
        FilledButton.icon(
          onPressed: onStart,
          icon: const Icon(Icons.camera_alt),
          label: const Text('Start scanning'),
          style:
              FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
        ),
        const SizedBox(height: 40),
        _howStep('STEP 1', 'Add a photo',
            'Upload or take a picture of one leaf.'),
        _howStep('STEP 2', 'Read the analysis',
            'Disease, accuracy, cause, effects and treatment.'),
        _howStep('STEP 3', 'Ask the assistant',
            'Go deeper with follow-up questions.'),
      ],
    );
  }

  Widget _howStep(String tag, String title, String body) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFD0E7E3)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(tag,
              style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: Color(0xFF0B8379),
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title,
              style: GoogleFonts.bricolageGrotesque(
                  fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(body, style: TextStyle(color: Colors.grey.shade700)),
        ]),
      );
}

// ================== SCAN ==================
class _ScanPage extends StatelessWidget {
  final File? image;
  final List<Detection> detections;
  final bool ready;
  final String? error;
  final VoidCallback onPickCamera;
  final VoidCallback onPickGallery;
  final VoidCallback onScan;
  final List<String> samples;
  final Future<void> Function(String assetPath, String label) onSampleTap;

  const _ScanPage({
    required this.image,
    required this.detections,
    required this.ready,
    required this.error,
    required this.onPickCamera,
    required this.onPickGallery,
    required this.onScan,
    required this.samples,
    required this.onSampleTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Add your leaf photo',
            style: GoogleFonts.bricolageGrotesque(
                fontSize: 26, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        Container(
          height: 320,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFD0E7E3)),
          ),
          clipBehavior: Clip.antiAlias,
          child: image == null
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image_outlined,
                          size: 64, color: Color(0xFF0B8379)),
                      SizedBox(height: 12),
                      Text('Add a leaf photo'),
                    ],
                  ),
                )
              : DetectionImage(file: image!, detections: detections),
        ),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onPickGallery,
              icon: const Icon(Icons.photo_library),
              label: const Text('Gallery'),
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onPickCamera,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Camera'),
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48)),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: (image != null && ready) ? onScan : null,
          icon: const Icon(Icons.search),
          label: Text(error != null
              ? 'Model error - check logs'
              : (ready ? 'Scan leaf' : 'Loading model...')),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        ),
        if (error != null) ...[
          const SizedBox(height: 8),
          Text('Model error: $error',
              style: const TextStyle(color: Colors.red, fontSize: 12)),
        ],
        if (samples.isNotEmpty) ...[
          const SizedBox(height: 28),
          Text('No photo handy? Try a sample leaf',
              style: GoogleFonts.bricolageGrotesque(
                  fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Row(
            children: [
              for (int i = 0; i < samples.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                _SampleTile(
                  asset: samples[i],
                  label: 'Sample ${i + 1}',
                  onTap: () => onSampleTap(samples[i], '${i + 1}'),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Sample leaves are optional. Your own photos get a live AI scan.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
          ),
        ],
        const SizedBox(height: 28),
        Text('Tips',
            style: GoogleFonts.bricolageGrotesque(
                fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        ...[
          'Photograph one leaf, filling most of the frame.',
          'Use daylight and keep the leaf in focus.',
          'Pick a leaf that shows the damage clearly.',
        ].map((s) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                const Icon(Icons.circle, size: 6, color: Color(0xFF0B8379)),
                const SizedBox(width: 8),
                Expanded(child: Text(s)),
              ]),
            )),
      ],
    );
  }
}

class _SampleTile extends StatelessWidget {
  final String asset;
  final String label;
  final VoidCallback onTap;
  const _SampleTile(
      {required this.asset, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFD0E7E3), width: 2),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(children: [
            AspectRatio(
              aspectRatio: 1,
              child: Image.asset(
                asset,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFFE7F6F3),
                  child: const Icon(Icons.eco, color: Color(0xFF0B8379)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(6),
              child: Text(label, style: const TextStyle(fontSize: 12.5)),
            ),
          ]),
        ),
      ),
    );
  }
}

class _ScanningDialog extends StatelessWidget {
  const _ScanningDialog();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Scanning your leaf...'),
              SizedBox(height: 6),
              Text('Comparing with known tomato diseases',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}

// ================== RESULT ==================
class _ResultPage extends StatelessWidget {
  final DiseaseInfo? info;
  final double? conf;
  final File? image;
  final List<Detection> detections;
  final VoidCallback onChat;
  final VoidCallback onBack;

  const _ResultPage({
    required this.info,
    required this.conf,
    required this.image,
    required this.detections,
    required this.onChat,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    if (info == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.analytics_outlined,
                size: 64, color: Color(0xFF0B8379)),
            const SizedBox(height: 12),
            const Text('No scan yet'),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: onBack, child: const Text('Go to Scan')),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Scan another leaf',
          ),
          Expanded(
            child: Text('Leaf analysis',
                style: GoogleFonts.bricolageGrotesque(
                    fontSize: 22, fontWeight: FontWeight.w800)),
          ),
          FilledButton.icon(
            onPressed: onChat,
            icon: const Icon(Icons.chat_bubble_outline, size: 18),
            label: const Text('Assistant'),
          ),
        ]),
        const SizedBox(height: 12),
        _HeroCard(info: info!, conf: conf ?? 0),
        const SizedBox(height: 16),
        if (image != null)
          DetectionImage(file: image!, detections: detections),
        const SizedBox(height: 16),
        if (detections.isNotEmpty) _AllDetections(detections: detections),
        if (info!.cause.isNotEmpty)
          _Section(title: 'What causes it', body: Text(info!.cause)),
        if (info!.effects.isNotEmpty)
          _Section(
              title: 'Effects on your plants', body: _bullets(info!.effects)),
        if (info!.stopNow.isNotEmpty)
          _Section(title: 'How to stop it now', body: _bullets(info!.stopNow)),
        if (info!.preventSpread.isNotEmpty)
          _Section(
              title: 'Stop it spreading', body: _bullets(info!.preventSpread)),
        if (info!.preventFuture.isNotEmpty)
          _Section(
              title: 'Prevent it next time',
              body: _bullets(info!.preventFuture)),
        if (info!.treatments.isNotEmpty)
          _Section(
            title: 'Medications and treatments',
            body: Column(
              children: info!.treatments
                  .map((t) => _TreatmentCard(t: t))
                  .toList(),
            ),
          ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0B8379),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Want to know more?',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text(
                'Ask about dosage, timing, organic options, fruit safety.',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: onChat,
                style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2CCBBA),
                    foregroundColor: const Color(0xFF06403B)),
                child: const Text('Open AI Assistant'),
              ),
            ],
          ),
        ),
        if (info!.seeExpertIf.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('See an expert if: ${info!.seeExpertIf}',
              style: const TextStyle(fontSize: 13, color: Colors.grey)),
        ],
        const SizedBox(height: 20),
        const Text(
          'LeafScan gives an AI estimate from one photo, not a lab test. '
          'Confirm serious outbreaks with your local extension officer.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _bullets(List<String> items) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items
            .map((s) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Icon(Icons.circle,
                            size: 6, color: Color(0xFF0B8379)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(s)),
                    ],
                  ),
                ))
            .toList(),
      );
}

class _HeroCard extends StatelessWidget {
  final DiseaseInfo info;
  final double conf;
  const _HeroCard({required this.info, required this.conf});

  @override
  Widget build(BuildContext context) {
    final isHealthy = info.type == 'none';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD0E7E3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          SizedBox(
            width: 96,
            height: 96,
            child: Stack(alignment: Alignment.center, children: [
              SizedBox(
                width: 96,
                height: 96,
                child: CircularProgressIndicator(
                  value: (conf / 100).clamp(0.0, 1.0),
                  strokeWidth: 10,
                  backgroundColor: const Color(0xFFE7F6F3),
                  valueColor: AlwaysStoppedAnimation(isHealthy
                      ? const Color(0xFF0B7A4B)
                      : const Color(0xFF0B8379)),
                ),
              ),
              Column(mainAxisSize: MainAxisSize.min, children: [
                Text('${conf.toStringAsFixed(0)}%',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 20)),
                const Text('ACCURACY',
                    style: TextStyle(fontSize: 9, letterSpacing: 1)),
              ]),
            ]),
          ),
          const SizedBox(width: 16),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(isHealthy ? 'RESULT: HEALTHY' : 'DETECTED',
                  style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.2,
                      color: Colors.grey.shade600)),
              Text(info.name,
                  style: GoogleFonts.bricolageGrotesque(
                      fontSize: 26, fontWeight: FontWeight.w800)),
              if (info.scientificName.isNotEmpty)
                Text(info.scientificName,
                    style: const TextStyle(
                        fontStyle: FontStyle.italic, color: Colors.grey)),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          if (info.type != 'none')
            Chip(
              label: Text(info.type.toUpperCase(),
                  style: const TextStyle(fontSize: 11)),
              backgroundColor: const Color(0xFFE7F6F3),
              side: BorderSide.none,
            ),
          if (conf < 60)
            const Chip(
              label: Text('LOW CONFIDENCE',
                  style: TextStyle(fontSize: 11, color: Colors.white)),
              backgroundColor: Color(0xFF8F5A00),
              side: BorderSide.none,
            ),
        ]),
        const SizedBox(height: 12),
        Text(info.summary, style: const TextStyle(fontSize: 15)),
      ]),
    );
  }
}

class _AllDetections extends StatelessWidget {
  final List<Detection> detections;
  const _AllDetections({required this.detections});

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'All detections (${detections.length})',
      body: Column(
        children: detections
            .map((d) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(children: [
                    Expanded(child: Text(d.label)),
                    Text('${(d.confidence * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold)),
                  ]),
                ))
            .toList(),
      ),
    );
  }
}

class _TreatmentCard extends StatelessWidget {
  final Treatment t;
  const _TreatmentCard({required this.t});

  Color get _kindColor => switch (t.kind) {
        'organic' => const Color(0xFFDDF5EA),
        'chemical' => const Color(0xFFFCEFCF),
        _ => const Color(0xFFE7F6F3),
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3FAF9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD0E7E3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
                color: _kindColor, borderRadius: BorderRadius.circular(6)),
            child: Text(t.kind.toUpperCase(),
                style: const TextStyle(
                    fontSize: 10, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(t.name,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ]),
        if (t.activeIngredient.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(t.activeIngredient,
                style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Colors.grey)),
          ),
        const SizedBox(height: 6),
        Text(t.how),
      ]),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget body;
  const _Section({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD0E7E3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.bricolageGrotesque(
                  fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          body,
        ],
      ),
    );
  }
}

// ================== CHAT ==================
class _ChatPage extends StatefulWidget {
  final DiseaseInfo? info;
  final VoidCallback onBack;
  const _ChatPage({this.info, required this.onBack});
  @override
  State<_ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<_ChatPage> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final List<Map<String, String>> _msgs = [];
  bool _sending = false;

  static const _suggestions = [
    'How do I stop it spreading?',
    'Is it safe to eat the fruit?',
    'What can I spray, and how often?',
    'Can I use organic methods?',
    'How should I space and water my plants?',
  ];

  @override
  void initState() {
    super.initState();
    _msgs.add({
      'role': 'ai',
      'text': widget.info != null
          ? 'Hi! I\'ve looked at your scan: **${widget.info!.name}**. '
              'Ask me anything about it - treatment, spraying, organic options, or fruit safety.'
          : 'Scan a leaf first and I\'ll answer using your result. '
              'Ask general tomato questions in the meantime.'
    });
  }

  Future<void> _ask(String q) async {
    q = q.trim();
    if (q.isEmpty || _sending) return;
    setState(() {
      _msgs.add({'role': 'user', 'text': q});
      _sending = true;
    });
    _ctrl.clear();
    _scrollDown();

    final history = <Map<String, String>>[];
    for (final m in _msgs) {
      history.add({
        'role': m['role'] == 'user' ? 'user' : 'assistant',
        'content': m['text']!,
      });
    }
    final trimmed =
        history.length > 12 ? history.sublist(history.length - 12) : history;

    final answer = await askAssistant(
      history: trimmed,
      lastUserText: q,
      info: widget.info,
    );
    if (!mounted) return;
    setState(() {
      _msgs.add({'role': 'ai', 'text': answer});
      _sending = false;
    });
    _scrollDown();
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(children: [
          IconButton(
            onPressed: widget.onBack,
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Back',
          ),
          Expanded(
            child: Text('AI Assistant',
                style: GoogleFonts.bricolageGrotesque(
                    fontSize: 22, fontWeight: FontWeight.w800)),
          ),
        ]),
      ),
      if (widget.info != null)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          color: const Color(0xFFE7F6F3),
          child: Text('Diagnosis: ${widget.info!.name}',
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
      Expanded(
        child: ListView.builder(
          controller: _scroll,
          padding: const EdgeInsets.all(12),
          itemCount: _msgs.length,
          itemBuilder: (_, i) {
            final m = _msgs[i];
            final isUser = m['role'] == 'user';
            return Align(
              alignment:
                  isUser ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.82),
                decoration: BoxDecoration(
                  color: isUser
                      ? const Color(0xFF0B8379)
                      : const Color(0xFFE7F6F3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: _renderMessage(m['text']!, isUser),
              ),
            );
          },
        ),
      ),
      SizedBox(
        height: 44,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          children: _suggestions
              .map((s) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(s, style: const TextStyle(fontSize: 12.5)),
                      onPressed: _sending ? null : () => _ask(s),
                    ),
                  ))
              .toList(),
        ),
      ),
      SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  minLines: 1,
                  maxLines: 5,
                  enabled: !_sending,
                  onSubmitted: (_) => _ask(_ctrl.text),
                  decoration: InputDecoration(
                    hintText: 'Ask a question...',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _sending ? null : () => _ask(_ctrl.text),
                icon: _sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ),
    ]);
  }

  Widget _renderMessage(String text, bool isUser) {
    final spans = <TextSpan>[];
    final pattern = RegExp(r'\*\*(.+?)\*\*');
    int last = 0;
    for (final match in pattern.allMatches(text)) {
      if (match.start > last) {
        spans.add(TextSpan(text: text.substring(last, match.start)));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ));
      last = match.end;
    }
    if (last < text.length) spans.add(TextSpan(text: text.substring(last)));

    return RichText(
      text: TextSpan(
        style: TextStyle(
          color: isUser ? Colors.white : Colors.black87,
          fontSize: 14.5,
          height: 1.35,
        ),
        children: spans,
      ),
    );
  }
}
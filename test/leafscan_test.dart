import 'package:flutter_test/flutter_test.dart';
import 'package:leafscan/models/detector.dart';
import 'package:leafscan/models/disease_info.dart';
import 'package:leafscan/services/chat.dart';

void main() {
  group('TomatoDetector.cleanLabel', () {
    test('maps raw model labels to display names', () {
      expect(TomatoDetector.cleanLabel('powedry_mildew'), 'Powdery Mildew');
      expect(TomatoDetector.cleanLabel('Healthy Leaf-'), 'Healthy Leaf');
      expect(TomatoDetector.cleanLabel('bactarial canker'), 'Bacterial Canker');
      expect(TomatoDetector.cleanLabel('late_blight'), 'Late Blight');
    });

    test('passes unknown labels through unchanged', () {
      expect(TomatoDetector.cleanLabel('mystery'), 'mystery');
    });
  });

  group('disease database', () {
    // Every cleaned label the model can emit must resolve to guidance.
    const cleanedLabels = [
      'Aphids',
      'Early Blight',
      'Healthy Leaf',
      'Leaf Curl',
      'Leafhoppers and Jassids',
      'Molds',
      'Mosaic Virus',
      'Septoria',
      'Bacterial Canker',
      'Bacterial Spot',
      'Flea Beetle',
      'Late Blight',
      'Leafminer',
      'Powdery Mildew',
      'Yellow Curl Virus',
    ];

    test('covers every model class', () {
      for (final label in cleanedLabels) {
        expect(kDiseaseDb.containsKey(label), isTrue,
            reason: 'Missing DiseaseInfo for "$label"');
      }
    });

    test('every entry has a summary', () {
      for (final entry in kDiseaseDb.entries) {
        expect(entry.value.summary, isNotEmpty,
            reason: '${entry.key} has an empty summary');
      }
    });

    test('fallback info is well formed', () {
      final info = fallbackInfo('Something New');
      expect(info.name, 'Something New');
      expect(info.type, 'unclear');
      expect(info.stopNow, isNotEmpty);
    });
  });

  group('assistant', () {
    final blight = kDiseaseDb['Early Blight']!;

    test('prompts to scan when no diagnosis yet', () {
      final a = answerQuestion('what should I do?', null);
      expect(a.toLowerCase(), contains('scan a leaf'));
    });

    test('answers spread questions from the diagnosis', () {
      final a = answerQuestion('how do I stop it spreading?', blight);
      expect(a, contains('Early blight'));
      expect(a, contains('- '));
    });

    test('answers spray questions with chemical treatments', () {
      final a = answerQuestion('what can I spray and how often?', blight);
      expect(a.toLowerCase(), contains('mancozeb'));
    });

    test('answers organic questions', () {
      final a = answerQuestion('can I use organic methods?', blight);
      expect(a.toLowerCase(), contains('non-chemical'));
    });

    test('answers fruit safety questions', () {
      final a = answerQuestion('is it safe to eat the fruit?', blight);
      expect(a.toLowerCase(), contains('wash fruit'));
    });

    test('falls back to stop-now guidance for unhandled questions', () {
      final a = answerQuestion('hello there', blight);
      expect(a, contains('Early blight'));
    });
  });
}

// lib/services/chat.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/disease_info.dart';

/// DeepSeek API key (kept out of source control).
///
/// Provide it at build time:
///   flutter build apk --dart-define=DEEPSEEK_API_KEY=sk-...
///
/// Without it, the assistant falls back to the offline guidance below.
///
/// SECURITY: any key compiled into a mobile app can be extracted from the APK.
/// For a public release, proxy requests through your own server and keep the
/// key server-side.
const String kDeepSeekApiKey = String.fromEnvironment(
  'DEEPSEEK_API_KEY',
  defaultValue: '',
);

const String _endpoint = 'https://api.deepseek.com/chat/completions';
const String _model = 'deepseek-chat';

String _systemPrompt(DiseaseInfo? info) {
  final b = StringBuffer()
    ..writeln('You are LeafScan, a friendly assistant for tomato plant health.')
    ..writeln(
        'Give practical, low-cost advice for smallholder farmers. Prefer organic '
        'and cultural controls; mention chemical options with a reminder to follow '
        'the product label and wear protective gear.')
    ..writeln('Keep answers short and clear (a few sentences or bullets). '
        'Never give medical advice.');
  if (info != null) {
    b
      ..writeln()
      ..writeln('Current diagnosis from the photo: ${info.name} (${info.type}).')
      ..writeln('Summary: ${info.summary}')
      ..writeln('Cause: ${info.cause}');
    if (info.effects.isNotEmpty) {
      b.writeln('Effects: ${info.effects.join('; ')}');
    }
    if (info.stopNow.isNotEmpty) {
      b.writeln('Act now: ${info.stopNow.join('; ')}');
    }
    if (info.preventSpread.isNotEmpty) {
      b.writeln('Stop spread: ${info.preventSpread.join('; ')}');
    }
    if (info.preventFuture.isNotEmpty) {
      b.writeln('Prevent next season: ${info.preventFuture.join('; ')}');
    }
    if (info.treatments.isNotEmpty) {
      b.writeln('Treatments: ${info.treatments.map((t) => '${t.name} '
          '(${t.kind}${t.activeIngredient.isNotEmpty ? ', ${t.activeIngredient}' : ''})'
          ' - ${t.how}').join('; ')}');
    }
    b.writeln('Answer using this diagnosis where relevant.');
  } else {
    b.writeln('The user has not scanned a leaf yet; answer general tomato '
        'questions and encourage them to scan one.');
  }
  return b.toString();
}

/// Sends the conversation to DeepSeek and returns the assistant reply.
/// Falls back to the offline rule-based answer if the request fails.
Future<String> askAssistant({
  required List<Map<String, String>> history,
  required String lastUserText,
  DiseaseInfo? info,
}) async {
  if (kDeepSeekApiKey.isEmpty) return answerQuestion(lastUserText, info);

  try {
    final messages = <Map<String, String>>[
      {'role': 'system', 'content': _systemPrompt(info)},
      ...history,
    ];
    final resp = await http
        .post(
          Uri.parse(_endpoint),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $kDeepSeekApiKey',
          },
          body: jsonEncode({
            'model': _model,
            'messages': messages,
            'temperature': 0.3,
            'max_tokens': 700,
            'stream': false,
          }),
        )
        .timeout(const Duration(seconds: 45));

    if (resp.statusCode == 200) {
      final data = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
      final choices = data['choices'] as List?;
      if (choices != null && choices.isNotEmpty) {
        final content =
            (choices.first['message']['content'] as String?)?.trim() ?? '';
        if (content.isNotEmpty) return content;
      }
    }
    return '_Online assistant unavailable (HTTP ${resp.statusCode})._\n\n'
        '${answerQuestion(lastUserText, info)}';
  } catch (_) {
    return '_You appear to be offline - here is the built-in guidance._\n\n'
        '${answerQuestion(lastUserText, info)}';
  }
}

/// Offline, rule-based assistant.
/// Uses the current diagnosis when present; otherwise answers general tomato Qs.
String answerQuestion(String q, DiseaseInfo? info) {
  if (info == null) {
    return 'Scan a leaf first and I\'ll answer using your result.\n\n'
        'In the meantime, in general:\n'
        '- Water tomatoes at the base, in the morning\n'
        '- Remove spotted lower leaves early\n'
        '- Rotate beds every season';
  }
  final t = q.toLowerCase();

  if (t.contains('spread') ||
      t.contains('other plants') ||
      t.contains('infect') ||
      t.contains('contain')) {
    if (info.preventSpread.isEmpty) {
      return 'No specific guidance for this result.';
    }
    return 'To stop **${info.name}** spreading:\n'
        '${info.preventSpread.take(5).map((s) => '- $s').join('\n')}';
  }

  if (t.contains('eat') ||
      t.contains('safe') ||
      t.contains('fruit') ||
      t.contains('harvest')) {
    return 'Wash fruit; discard anything with brown patches or soft spots.\n\n'
        'If you sprayed, respect the pre-harvest interval on the label.';
  }

  if (t.contains('spray') ||
      t.contains('dose') ||
      t.contains('dosage') ||
      t.contains('chemical') ||
      t.contains('medic') ||
      t.contains('fungicide') ||
      t.contains('schedule') ||
      t.contains('how often')) {
    final chems = info.treatments.where((x) => x.kind == 'chemical').toList();
    final list = chems.isEmpty ? info.treatments : chems;
    if (list.isEmpty) return 'No specific spray listed for this result.';
    return 'Options for **${info.name}**:\n'
        '${list.map((x) => '- **${x.name}**${x.activeIngredient.isNotEmpty ? " (${x.activeIngredient})" : ""}: ${x.how}').join('\n')}\n\n'
        'Follow the label and wear protective gear.';
  }

  if (t.contains('organic') ||
      t.contains('natural') ||
      t.contains('neem') ||
      t.contains('without chemical')) {
    final org = info.treatments.where((x) => x.kind != 'chemical').toList();
    if (org.isEmpty) {
      return 'No specific organic options listed. Focus on cultural control.';
    }
    return 'Non-chemical options:\n'
        '${org.map((x) => '- **${x.name}**: ${x.how}').join('\n')}';
  }

  if (t.contains('water') ||
      t.contains('space') ||
      t.contains('spacing') ||
      t.contains('irrigat') ||
      t.contains('mulch') ||
      t.contains('prune') ||
      t.contains('stake') ||
      t.contains('prevent') ||
      t.contains('future')) {
    if (info.preventFuture.isEmpty) {
      return 'No specific prevention listed.';
    }
    return 'For prevention next season:\n'
        '${info.preventFuture.take(5).map((s) => '- $s').join('\n')}';
  }

  if (t.contains('cause') || t.contains('why') || t.contains('how did')) {
    return info.cause.isEmpty
        ? 'Cause not documented for this result.'
        : info.cause;
  }

  if (t.contains('effect') ||
      t.contains('damage') ||
      t.contains('yield') ||
      t.contains('harm')) {
    if (info.effects.isEmpty) return 'No specific effects listed.';
    return 'Effects on your plants:\n'
        '${info.effects.map((s) => '- $s').join('\n')}';
  }

  if (t.contains('now') || t.contains('today') || t.contains('urgent')) {
    if (info.stopNow.isEmpty) return 'Nothing urgent for this result.';
    return 'Do this now:\n'
        '${info.stopNow.map((s) => '- $s').join('\n')}';
  }

  if (info.stopNow.isEmpty) {
    return 'Nothing specific to do - monitor the plant.';
  }
  return 'For **${info.name}**, focus on:\n'
      '${info.stopNow.take(3).map((s) => '- $s').join('\n')}\n\n'
      'Ask about spraying, spread, organic options, or fruit safety.';
}
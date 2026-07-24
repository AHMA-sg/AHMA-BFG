import 'dart:math';

const String defaultAffirmation =
    "You don't have to have it all figured out. Resting is also moving forward.";

class SummaryQuote {
  final String text;
  final bool isFromSummary;

  const SummaryQuote({required this.text, required this.isFromSummary});
}

/// Selects a short, empowering sentence from summaries ordered newest-first.
///
/// New summaries are prompted to include a second-person closing sentence.
/// The scoring also supports older summaries and lightly converts common
/// third-person journal phrasing into second person without adding new facts.
SummaryQuote selectEmpoweringSummaryQuote(Iterable<String> summaries) {
  final candidates = _empoweringCandidates(summaries);
  if (candidates.isEmpty) return _fallbackQuote;

  candidates.sort((a, b) => b.score.compareTo(a.score));
  return _quoteFromSentence(candidates.first.sentence);
}

/// Randomly selects an empowering sentence using a stable per-session seed.
SummaryQuote selectRandomEmpoweringSummaryQuote(
  Iterable<String> summaries, {
  required int sessionSeed,
}) {
  final candidates = _empoweringCandidates(summaries);
  if (candidates.isEmpty) return _fallbackQuote;

  final selected = candidates[Random(sessionSeed).nextInt(candidates.length)];
  return _quoteFromSentence(selected.sentence);
}

const SummaryQuote _fallbackQuote = SummaryQuote(
  text: defaultAffirmation,
  isFromSummary: false,
);

SummaryQuote _quoteFromSentence(String sentence) {
  return SummaryQuote(
    text: _personalizeJournalSentence(sentence),
    isFromSummary: true,
  );
}

List<_QuoteCandidate> _empoweringCandidates(Iterable<String> summaries) {
  final candidates = <_QuoteCandidate>[];
  var summaryIndex = 0;

  for (final summary in summaries) {
    for (final rawSentence in _sentences(summary)) {
      final sentence = _cleanSentence(rawSentence);
      if (sentence.length < 28 || sentence.length > 165) continue;

      final lower = sentence.toLowerCase();
      if (sentence.endsWith('?') ||
          lower.contains('http://') ||
          lower.contains('https://') ||
          lower.contains('@') ||
          lower.contains(' should ') ||
          lower.contains(' must ')) {
        continue;
      }

      var score = summaryIndex == 0 ? 2 : 0;
      if (RegExp(r"\b(you|your|you've|you're)\b").hasMatch(lower)) {
        score += 6;
      }
      if (RegExp(
        r'\b(the caregiver|the caller|they|their)\b',
      ).hasMatch(lower)) {
        score += 1;
      }

      for (final signal in _empoweringSignals) {
        if (lower.contains(signal)) score += 2;
      }

      if (score >= 5) {
        candidates.add(_QuoteCandidate(sentence: sentence, score: score));
      }
    }
    summaryIndex++;
  }

  return candidates;
}

class _QuoteCandidate {
  final String sentence;
  final int score;

  const _QuoteCandidate({required this.sentence, required this.score});
}

const List<String> _empoweringSignals = [
  'strength',
  'courage',
  'resilien',
  'progress',
  'effort',
  'managed',
  'manage ',
  'showed',
  'demonstrat',
  'deserve',
  'capable',
  'not alone',
  'moving forward',
  'small step',
  'continue',
  'kept going',
  'reached out',
  'asked for help',
  'made space',
  'protect',
  'rest',
];

Iterable<String> _sentences(String summary) sync* {
  final normalized = summary
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim()
      // If a lowercase word or punctuation continues after the abbreviation,
      // neither period ends the sentence.
      .replaceAllMapped(
        RegExp(r'\b([apAP])\.m\.(?=\s+[a-z]|[,;:])'),
        (match) => '${match.group(1)}\u2024m\u2024',
      )
      // Keep the internal period in time abbreviations from looking like the
      // end of a sentence. The final period is intentionally left intact.
      .replaceAllMapped(
        RegExp(r'\b([ap])\.m\.', caseSensitive: false),
        (match) => '${match.group(1)}\u2024m.',
      );
  if (normalized.isEmpty) return;

  final matches = RegExp(r'[^.!?]+(?:[.!?]+|$)').allMatches(normalized);
  for (final match in matches) {
    final sentence = match.group(0)?.replaceAll('\u2024', '.').trim();
    if (sentence != null && sentence.isNotEmpty) yield sentence;
  }
}

String _cleanSentence(String sentence) {
  return sentence
      .replaceFirst(RegExp(r'^[\s*"“”‘’\-–—•\d.)]+'), '')
      .replaceAll(RegExp(r'[*_]+'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

String _personalizeJournalSentence(String sentence) {
  var result = sentence
      .replaceAll(RegExp(r'\bThe caregiver\b', caseSensitive: false), 'You')
      .replaceAll(RegExp(r'\bThe caller\b', caseSensitive: false), 'You')
      .replaceAll(RegExp(r'\bthe caregiver\b', caseSensitive: false), 'you')
      .replaceAll(RegExp(r'\bthe caller\b', caseSensitive: false), 'you')
      .replaceAll(RegExp(r'\bTheir\b'), 'Your')
      .replaceAll(RegExp(r'\btheir\b'), 'your')
      .replaceAll(RegExp(r'\bThey\b'), 'You')
      .replaceAll(RegExp(r'\bthey\b'), 'you')
      .replaceAll(RegExp(r'\bthemselves\b', caseSensitive: false), 'yourself');

  const grammarFixes = {
    'You is ': 'You are ',
    'You was ': 'You were ',
    'You has ': 'You have ',
    'You shows ': 'You show ',
    'You showed ': 'You showed ',
    'You demonstrates ': 'You demonstrate ',
    'You continues ': 'You continue ',
    'You deserves ': 'You deserve ',
    'You manages ': 'You manage ',
    'You recognizes ': 'You recognize ',
    'You recognises ': 'You recognise ',
    'You remains ': 'You remain ',
    'You takes ': 'You take ',
    'You seeks ': 'You seek ',
  };
  grammarFixes.forEach((from, to) {
    result = result.replaceFirst(from, to);
  });
  result = result
      .replaceAll(' and deserves ', ' and deserve ')
      .replaceAll(' and continues ', ' and continue ')
      .replaceAll(' and shows ', ' and show ')
      .replaceAll(' and demonstrates ', ' and demonstrate ');
  return result;
}

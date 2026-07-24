import 'package:ahma_app/core/utils/summary_quote.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('prefers an empowering second-person sentence from recent summaries', () {
    final quote = selectEmpoweringSummaryQuote([
      'You described a difficult morning. You showed real strength by asking '
          'for support and making space to rest.',
      'You made progress last week.',
    ]);

    expect(
      quote.text,
      'You showed real strength by asking for support and making space to rest.',
    );
    expect(quote.isFromSummary, isTrue);
  });

  test('personalizes useful sentences from older third-person summaries', () {
    final quote = selectEmpoweringSummaryQuote([
      'The caregiver felt stretched thin. The caregiver continues to show '
          'courage and deserves support.',
    ]);

    expect(quote.text, 'You continue to show courage and deserve support.');
    expect(quote.isFromSummary, isTrue);
  });

  test('uses the default when no empowering sentence is available', () {
    final quote = selectEmpoweringSummaryQuote([
      'The appointment is at three in the afternoon.',
    ]);

    expect(quote.text, defaultAffirmation);
    expect(quote.isFromSummary, isFalse);
  });
}

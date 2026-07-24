import 'package:flutter_test/flutter_test.dart';
import 'package:ahma_app/data/models/action_plan.dart';

void main() {
  test('parses and serializes a call summary update', () {
    final update = BackendUpdate.fromJson({
      'type': 'call_summary_ready',
      'userId': 'user-123',
      'callId': 'call-123',
      'timestamp': '2026-07-18T08:00:00Z',
      'classification': {
        'primary_need': 'caregiver_support',
        'confidence': 1.0,
        'stress_level': 'regular',
      },
      'action_plan': {
        'summary': 'The caregiver shared that today felt heavy.',
        'calendar_events': <dynamic>[],
        'todoist_tasks': <dynamic>[],
        'resources': <dynamic>[],
        'reasoning': 'The caregiver shared that today felt heavy.',
      },
      'stats': <String, dynamic>{},
    });

    expect(update.type, 'call_summary_ready');
    expect(
      update.actionPlan.summary,
      'The caregiver shared that today felt heavy.',
    );
    expect(update.actionPlan.isEmpty, isTrue);
    expect(
      update.toJson()['action_plan']['summary'],
      'The caregiver shared that today felt heavy.',
    );
  });
}

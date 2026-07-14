import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ahma_app/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    dotenv.testLoad(fileInput: 'PROFILE_API_URL=http://localhost:5002');
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shows login screen when no session is restored', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();

    expect(find.text('AHMA'), findsOneWidget);
    expect(find.text('Your AI care resource companion'), findsOneWidget);
    expect(find.text('Email me a sign-in code'), findsOneWidget);
    expect(find.text('New to AHMA? Create your profile'), findsOneWidget);
  });
}

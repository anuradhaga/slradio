import 'package:flutter_test/flutter_test.dart';
import 'package:slradio/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    // Mock SharedPreferences values before each test
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Radio App smoke test - verifies UI rendering', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Verify that the title is displayed on the home screen dashboard
    expect(find.text('Sri Lanka Radio'), findsOneWidget);
    
    // Verify that the search input placeholder is present
    expect(find.text('Search stations, frequencies...'), findsOneWidget);

    // Verify that there are category filter pills (like 'All')
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Favorites'), findsOneWidget);
  });
}

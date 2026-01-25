import 'package:flutter_test/flutter_test.dart';
import 'package:home_story/homes/home_list_screen.dart';

import 'package:home_story/test/helpers/test_app.dart';

void main() {
  testWidgets('HomeListScreen renders successfully', (tester) async {
    await tester.pumpWidget(testApp(const HomeListScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Home Story'), findsOneWidget);
    expect(find.text('No homes yet'), findsOneWidget);
    expect(find.text('Tap the + button to add your first home'), findsOneWidget);
  });
}

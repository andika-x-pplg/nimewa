import 'package:flutter_test/flutter_test.dart';
import 'package:nimeva/main.dart';
import 'package:nimeva/presentation/screens/home_screen.dart';

void main() {
  testWidgets('NimevaApp smoke test builds HomeScreen', (WidgetTester tester) async {
    await tester.pumpWidget(const NimevaApp());
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
  });
}

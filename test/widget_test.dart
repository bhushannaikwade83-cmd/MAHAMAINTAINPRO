import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/main.dart';

void main() {
  testWidgets('MahaMaintain Pro app launches', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(
      child: MahaMaintainApp(),
    ));

    expect(find.text('Welcome to MahaMaintain Pro'), findsOneWidget);
  });
}

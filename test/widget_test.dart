import 'package:flutter_test/flutter_test.dart';

import 'package:asam_dev/app/app.dart';

void main() {
  testWidgets('ASAM dashboard loads', (WidgetTester tester) async {
    await tester.pumpWidget(const AsamApp());

    expect(find.text('ASAM'), findsOneWidget);
    expect(find.text('Good morning'), findsOneWidget);
    expect(find.text('TODAY'), findsOneWidget);
    expect(find.text('NEEDS ATTENTION'), findsOneWidget);
    expect(find.text('MARKETING'), findsOneWidget);
    expect(find.text('GOALS'), findsOneWidget);
    expect(find.text('CLIENT INTELLIGENCE'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:j_life/app.dart';

void main() {
  testWidgets('home presents core dashboard and navigation', (tester) async {
    await tester.pumpWidget(const JLifeApp());
    await tester.pumpAndSettle();

    expect(find.text('J의 삶'), findsOneWidget);
    expect(find.text('오늘'), findsWidgets);
    expect(find.text('예정'), findsWidgets);
    expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    expect(find.text('관리'), findsOneWidget);
  });

  testWidgets('free tier shows calm ad placeholder and pro hides it', (
    tester,
  ) async {
    await tester.pumpWidget(const JLifeApp());
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('광고가 표시될 자리'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('광고가 표시될 자리'), findsOneWidget);

    await tester.tap(find.text('관리'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('proPreviewSwitch')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('홈'));
    await tester.pumpAndSettle();
    expect(find.text('광고가 표시될 자리'), findsNothing);
  });
}

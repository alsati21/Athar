import 'package:flutter_test/flutter_test.dart';

import 'package:untitled4/main.dart';

void main() {
  testWidgets('Quran Reels studio loads with Arabic surah names', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const QuranReelsApp());

    expect(find.text('مقاطع قرآنية'), findsOneWidget);
    expect(find.text('إعدادات المقطع'), findsOneWidget);
    expect(find.text('الفاتحة'), findsOneWidget);
    expect(find.text('من آية'), findsOneWidget);
    expect(find.text('إلى آية'), findsOneWidget);
    expect(find.text('سيتم تضمين آية واحدة'), findsOneWidget);
  });
}

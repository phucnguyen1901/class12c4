import 'package:flutter_test/flutter_test.dart';

import 'package:class12c4/main.dart';

void main() {
  testWidgets('App loads with lock overlay', (WidgetTester tester) async {
    await tester.pumpWidget(const Class12c4App());
    await tester.pump();

    expect(find.textContaining('12C4'), findsWidgets);
    expect(find.text('Nhập mật khẩu để xem kỷ niệm'), findsOneWidget);
    expect(find.text('Mở khoá'), findsOneWidget);
  });
}

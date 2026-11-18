import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:achados_campus/main.dart';

void main() {
  testWidgets('o app abre', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: AchadosApp()));
    expect(find.byType(AchadosApp), findsOneWidget);
  });
}
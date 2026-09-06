import 'package:flutter_test/flutter_test.dart';
import 'package:fynox_fow/main.dart';

void main() {
  testWidgets('Fynox Fow starts successfully', (tester) async {
    await tester.pumpWidget(const FynoxFowApp());

    expect(find.text('Fynox Fow'), findsOneWidget);
  });
}
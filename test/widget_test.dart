import 'package:flutter_test/flutter_test.dart';

import 'package:ai_detector/main.dart';

void main() {
  testWidgets('App launches and shows the splash screen', (tester) async {
    await tester.pumpWidget(const MyApp(isFirstTime: true));

    // The splash screen title should be present in the widget tree.
    expect(find.text('ChitraVisionAI'), findsOneWidget);
    expect(find.text('AI DETECTION PLATFORM'), findsOneWidget);

    // The splash must eventually complete its intro animation.
    await tester.pump(const Duration(seconds: 4));
  });
}

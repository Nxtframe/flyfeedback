import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flyfeedback/flyfeedback.dart';

void main() {
  testWidgets('Popup shows and hides correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame
    await tester.pumpWidget(
      const MaterialApp(
        home: PopupTestWidget(),
      ),
    );

    // Verify that the popup is not shown initially
    expect(find.byType(AlertDialog), findsNothing);

    // Tap the button to show the popup
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    // Verify that the popup is shown
    expect(find.byType(AlertDialog), findsOneWidget);

    // Tap outside to dismiss the popup
    await tester.tapAt(Offset.zero);
    await tester.pumpAndSettle();

    // Verify that the popup is dismissed
    expect(find.byType(AlertDialog), findsNothing);
  });
}

class PopupTestWidget extends StatelessWidget {
  const PopupTestWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Popup(
          builder: (context, controller) => const Text('Test Popup'),
          child: ElevatedButton(
            onPressed: () {
              final popupController = PopupController();
              popupController.open();
            },
            child: const Text('Show Popup'),
          ),
        ),
      ),
    );
  }
}

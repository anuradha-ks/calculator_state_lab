
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:calculator_state_lab/main.dart';

void main() {
  Future<void> tapKey(
    WidgetTester tester,
    String key,
  ) async {
    await tester.tap(find.byKey(ValueKey(key)));
    await tester.pumpAndSettle();
  }

  String displayedValue(WidgetTester tester) {
    return tester.widget<Text>(
      find.byKey(const ValueKey('display')),
    ).data!;
  }

  Future<void> startApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1.0;

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const CalculatorApp());
    await tester.pumpAndSettle();
  }

  testWidgets('calculator displays zero initially', (tester) async {
    await startApp(tester);

    expect(displayedValue(tester), '0');
  });

  testWidgets('calculates from left to right', (tester) async {
    await startApp(tester);

    await tapKey(tester, 'digit_2');
    await tapKey(tester, 'op_add');
    await tapKey(tester, 'digit_3');
    await tapKey(tester, 'op_multiply');

    expect(displayedValue(tester), '5');

    await tapKey(tester, 'digit_4');
    await tapKey(tester, 'equals');

    expect(displayedValue(tester), '20');
  });

  testWidgets('replaces a repeated operator', (tester) async {
    await startApp(tester);

    await tapKey(tester, 'digit_9');
    await tapKey(tester, 'op_add');
    await tapKey(tester, 'op_multiply');
    await tapKey(tester, 'digit_2');
    await tapKey(tester, 'equals');

    expect(displayedValue(tester), '18');
  });

  testWidgets('supports decimal addition', (tester) async {
    await startApp(tester);

    await tapKey(tester, 'digit_1');
    await tapKey(tester, 'decimal');
    await tapKey(tester, 'digit_5');
    await tapKey(tester, 'op_add');
    await tapKey(tester, 'digit_2');
    await tapKey(tester, 'decimal');
    await tapKey(tester, 'digit_5');
    await tapKey(tester, 'equals');

    expect(displayedValue(tester), '4');
  });

  testWidgets('backspace removes the last digit', (tester) async {
    await startApp(tester);

    await tapKey(tester, 'digit_1');
    await tapKey(tester, 'digit_2');
    await tapKey(tester, 'digit_3');
    await tapKey(tester, 'backspace');

    expect(displayedValue(tester), '12');
  });

  testWidgets('clear resets the calculator', (tester) async {
    await startApp(tester);

    await tapKey(tester, 'digit_9');
    await tapKey(tester, 'clear');

    expect(displayedValue(tester), '0');
  });

  testWidgets('division by zero displays an error', (tester) async {
    await startApp(tester);

    await tapKey(tester, 'digit_8');
    await tapKey(tester, 'op_divide');
    await tapKey(tester, 'digit_0');
    await tapKey(tester, 'equals');

    expect(displayedValue(tester), 'Error');
    expect(
      find.byKey(const ValueKey('error_message')),
      findsOneWidget,
    );
  });


testWidgets('completed calculation appears in history',
    (tester) async {
  await startApp(tester);

  await tapKey(tester, 'digit_2');
  await tapKey(tester, 'op_add');
  await tapKey(tester, 'digit_3');
  await tapKey(tester, 'equals');

  expect(displayedValue(tester), '5');

  await tester.tap(find.byKey(const ValueKey('open_history')));
  await tester.pumpAndSettle();

  expect(find.text('Calculation History'), findsOneWidget);
  expect(find.textContaining('2 + 3 = 5'), findsOneWidget);
});

}

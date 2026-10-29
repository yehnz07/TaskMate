import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_application_1/main.dart';

void main() {
  testWidgets('student can add, complete, filter, edit, and delete a task',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MyApp());
    expect(find.text('Task Mate'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back!'), findsOneWidget);
    expect(
      find.text("You're all caught up! Add a task above to get started."),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('add-task-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save-task-button')));
    await tester.pumpAndSettle();
    expect(find.text('Enter a task title.'), findsOneWidget);
    expect(find.text('Enter a subject or category.'), findsOneWidget);
    expect(find.text('Choose a due date.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('task-title-field')),
      'Read biology chapter',
    );
    await tester.enterText(
      find.byKey(const Key('task-subject-field')),
      'Biology',
    );
    await tester.tap(find.byKey(const Key('choose-due-date-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save-task-button')));
    await tester.pumpAndSettle();

    expect(find.text('Read biology chapter'), findsOneWidget);
    expect(find.text('Biology'), findsOneWidget);
    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getString('task_mate_tasks_v1'),
      contains('Read biology chapter'),
    );

    final checkbox = find.byType(Checkbox).first;
    await tester.ensureVisible(checkbox);
    await tester.tap(checkbox);
    await tester.pumpAndSettle();
    expect(find.text('Completed'), findsWidgets);

    final pendingFilter = find.descendant(
      of: find.byKey(const Key('task-filters')),
      matching: find.text('Pending'),
    );
    await tester.tap(pendingFilter);
    await tester.pumpAndSettle();
    expect(find.text('No pending tasks. Great job!'), findsOneWidget);

    final completedFilter = find.descendant(
      of: find.byKey(const Key('task-filters')),
      matching: find.text('Completed'),
    );
    await tester.tap(completedFilter);
    await tester.pumpAndSettle();
    expect(find.text('Read biology chapter'), findsOneWidget);

    await tester.tap(find.byTooltip('Task actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('task-title-field')),
      'Review biology notes',
    );
    await tester.enterText(
      find.byKey(const Key('task-subject-field')),
      'Science',
    );
    await tester.tap(find.byKey(const Key('save-task-button')));
    await tester.pumpAndSettle();
    expect(find.text('Review biology notes'), findsOneWidget);
    expect(find.text('Science'), findsOneWidget);

    await tester.tap(find.byTooltip('Task actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Completed tasks will appear here.'), findsOneWidget);
  });

  testWidgets('loads tasks saved before the app starts',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'task_mate_tasks_v1':
          '[{"id":"saved-1","title":"Study chemistry","subject":"Chemistry","dueDate":"2026-10-30T00:00:00.000","isCompleted":false}]',
    });

    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('Study chemistry'), findsOneWidget);
    expect(find.text('Chemistry'), findsOneWidget);
    expect(find.text('1'), findsWidgets);
  });
}
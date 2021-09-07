import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:states_rebuilder/src/injected/injected_text_editing/injected_text_editing.dart';
import 'package:states_rebuilder/states_rebuilder.dart';

void main() {
  final InjectedTextEditing textEditing = RM.injectTextEditing(text: 'text');

  testWidgets(
    'WHEN an injected text editing is initialized with a non empty string'
    'THEN the the TextField is pre-filled with that string',
    (tester) async {
      final widget = MaterialApp(
        home: Material(
          child: TextField(
            controller: textEditing.controller,
          ),
        ),
      );

      await tester.pumpWidget(widget);
      expect(find.text('text'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'text');
      //
    },
  );

  testWidgets(
    'Listen to the injected text editing',
    (tester) async {
      final widget = MaterialApp(
        home: Material(
          child: Column(
            children: [
              TextField(
                controller: textEditing.controller,
              ),
              On(() {
                return Text(textEditing.text);
              }).listenTo(textEditing),
              On(() {
                return Text(textEditing.selection.toString());
              }).listenTo(textEditing),
              On(() {
                return Text(textEditing.composing.toString());
              }).listenTo(textEditing)
            ],
          ),
        ),
      );

      await tester.pumpWidget(widget);
      expect(find.text('text'), findsNWidgets(2));
      // expect(textEditing.selection.toString(),
      //     'TextSelection(baseOffset: -1, extentOffset: -1, affinity: TextAffinity.downstream, isDirectional: false)');
      // expect(textEditing.composing.toString(), 'TextRange(start: -1, end: -1)');

      await tester.enterText(find.byType(TextField), 'new text');

      await tester.pump();
      expect(find.text('new text'), findsNWidgets(2));
      // expect(textEditing.selection.toString(),
      //     'TextSelection(baseOffset: -1, extentOffset: -1, affinity: TextAffinity.downstream, isDirectional: false)');
      // expect(textEditing.composing.toString(), 'TextRange(start: -1, end: -1)');
    },
  );

  testWidgets(
    'WHEN validator is define'
    'THEN input is validated',
    (tester) async {
      final textEditing = RM.injectTextEditing(
        validators: [
          (val) {
            if (val?.contains('@') != true) {
              return 'Must contain @';
            }
          }
        ],
      );

      final widget = MaterialApp(
        home: Material(
          child: On(
            () => TextField(
              controller: textEditing.controller,
              decoration: InputDecoration(
                errorText: textEditing.error,
              ),
            ),
          ).listenTo(textEditing),
        ),
      );

      await tester.pumpWidget(widget);

      expect(find.text('Must contain @'), findsNothing);
      await tester.enterText(find.byType(TextField), 'new text');
      await tester.pump();
      expect(find.text('Must contain @'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'new text@');
      await tester.pump();
      expect(find.text('Must contain @'), findsNothing);
      await tester.enterText(find.byType(TextField), 'new text');
      await tester.pump();
      expect(find.text('Must contain @'), findsOneWidget);
    },
  );

  final InjectedForm form = RM.injectForm();
  final name = RM.injectTextEditing(
    validators: [(v) => v!.length > 3 ? null : 'Name Error'],
  );
  final email = RM.injectTextEditing(
    validators: [(v) => v!.length > 3 ? 'Email Error' : null],
  );
  testWidgets(
    'WHEN InjectedForm is used'
    'AND WHEN autovalidateMode = AutovalidateMode.disabled (the default)'
    'THEN the fields are validate manually by calling form.validate'
    'AND check form.isValid works',
    (tester) async {
      final widget = MaterialApp(
        home: Scaffold(
          body: On.form(
            () {
              return Column(
                children: [
                  TextField(
                    key: Key('Name'),
                    controller: name.controller,
                    decoration: InputDecoration(errorText: name.error),
                  ),
                  TextField(
                    key: Key('Email'),
                    controller: email.controller,
                    decoration: InputDecoration(errorText: email.error),
                  ),
                ],
              );
            },
          ).listenTo(form),
        ),
      );

      await tester.pumpWidget(widget);
      expect(find.text('Name Error'), findsNothing);
      expect(find.text('Email Error'), findsNothing);
      await tester.enterText(find.byKey(Key('Name')), 'na');
      await tester.enterText(find.byKey(Key('Email')), 'em');
      await tester.pump();
      expect(find.text('Name Error'), findsNothing);
      expect(find.text('Email Error'), findsNothing);
      expect(form.isValid, false);
      form.validate();
      await tester.pump();
      expect(find.text('Name Error'), findsOneWidget);
      expect(find.text('Email Error'), findsNothing);
      expect(form.isValid, false);

      //
      await tester.enterText(find.byKey(Key('Name')), 'name');
      await tester.enterText(find.byKey(Key('Email')), 'email');
      await tester.pump();
      expect(find.text('Name Error'), findsOneWidget);
      expect(find.text('Email Error'), findsNothing);
      form.validate();
      await tester.pump();
      expect(find.text('Name Error'), findsNothing);
      expect(find.text('Email Error'), findsOneWidget);
      expect(form.isValid, false);
      form.reset();
      await tester.pump();
      expect(find.text('Name Error'), findsNothing);
      expect(find.text('Email Error'), findsNothing);
      expect(form.isValid, false);
    },
  );

  testWidgets(
    'WHEN InjectedForm is used'
    'AND WHEN autovalidateMode = AutovalidateMode.always '
    'THEN the fields are validate always validated'
    'AND check form.reset works',
    (tester) async {
      final form = RM.injectForm(
        autovalidateMode: AutovalidateMode.always,
      );

      final widget = MaterialApp(
        home: Scaffold(
          body: On.form(
            () {
              return Column(
                children: [
                  TextField(
                    key: Key('Name'),
                    controller: name.controller,
                    decoration: InputDecoration(errorText: name.error),
                  ),
                  TextField(
                    key: Key('Email'),
                    controller: email.controller,
                    decoration: InputDecoration(errorText: email.error),
                  ),
                ],
              );
            },
          ).listenTo(form),
        ),
      );

      await tester.pumpWidget(widget);
      await tester.pump(); //add frame
      expect(find.text('Name Error'), findsOneWidget);
      expect(find.text('Email Error'), findsNothing);
      await tester.enterText(find.byKey(Key('Name')), 'na');
      await tester.enterText(find.byKey(Key('Email')), 'em');
      await tester.pump();
      expect(find.text('Name Error'), findsOneWidget);
      expect(find.text('Email Error'), findsNothing);

      //
      await tester.enterText(find.byKey(Key('Name')), 'name');
      await tester.enterText(find.byKey(Key('Email')), 'email');
      await tester.pump();
      expect(find.text('Name Error'), findsNothing);
      expect(find.text('Email Error'), findsOneWidget);

      form.reset();
      await tester.pump();
      expect(name.text, '');
      expect(email.text, '');
      expect(find.text('Name Error'), findsOneWidget);
      expect(find.text('Email Error'), findsNothing);
      expect(form.isValid, false);
    },
  );

  testWidgets(
    'WHEN InjectedForm is used'
    'AND WHEN autovalidateMode = AutovalidateMode.onUserInteraction '
    'THEN the fields are validate on user interaction',
    (tester) async {
      final form = RM.injectForm(
        autovalidateMode: AutovalidateMode.onUserInteraction,
      );

      final widget = MaterialApp(
        home: Scaffold(
          body: On.form(
            () {
              return Column(
                children: [
                  TextField(
                    key: Key('Name'),
                    controller: name.controller,
                    decoration: InputDecoration(errorText: name.error),
                  ),
                  TextField(
                    key: Key('Email'),
                    controller: email.controller,
                    decoration: InputDecoration(errorText: email.error),
                  ),
                ],
              );
            },
          ).listenTo(form),
        ),
      );

      await tester.pumpWidget(widget);
      await tester.pump(); //add frame
      expect(find.text('Name Error'), findsNothing);
      expect(find.text('Email Error'), findsNothing);
      await tester.enterText(find.byKey(Key('Name')), 'na');
      await tester.enterText(find.byKey(Key('Email')), 'em');
      await tester.pump();
      expect(find.text('Name Error'), findsOneWidget);
      expect(find.text('Email Error'), findsNothing);

      //
      await tester.enterText(find.byKey(Key('Name')), 'name');
      await tester.enterText(find.byKey(Key('Email')), 'email');
      await tester.pump();
      expect(find.text('Name Error'), findsNothing);
      expect(find.text('Email Error'), findsOneWidget);
      form.reset();
      await tester.pump();
      expect(find.text('Name Error'), findsNothing);
      expect(find.text('Email Error'), findsNothing);
      expect(form.isValid, false);
    },
  );

  testWidgets(
    'WHEN autoDispose is set to false'
    'THEN the injected text editing is keeps its value',
    (tester) async {
      final name = RM.injectTextEditing(
        autoDispose: false,
      );

      final switcher = true.inj();

      final widget = MaterialApp(
        home: Scaffold(
          body: On.form(
            () {
              return On(() {
                if (switcher.state) {
                  return Column(
                    children: [
                      TextField(
                        key: Key('Name'),
                        controller: name.controller,
                        decoration: InputDecoration(errorText: name.error),
                      ),
                      TextField(
                        key: Key('Email'),
                        controller: email.controller,
                        decoration: InputDecoration(errorText: email.error),
                      ),
                    ],
                  );
                }
                return Container();
              }).listenTo(switcher);
            },
          ).listenTo(form),
        ),
      );
      await tester.pumpWidget(widget);
      expect(name.text, '');
      expect(email.text, '');
      await tester.enterText(find.byKey(Key('Name')), 'name');
      await tester.enterText(find.byKey(Key('Email')), 'email');
      await tester.pump();
      expect(name.text, 'name');
      expect(email.text, 'email');
      expect(find.text('name'), findsOneWidget);
      expect(find.text('email'), findsOneWidget);
      //
      switcher.toggle();
      await tester.pump();
      switcher.toggle();
      await tester.pump();
      expect(name.text, 'name');
      expect(email.text, '');
      expect(find.text('name'), findsOneWidget);
      expect(find.text('email'), findsNothing);
    },
  );
  testWidgets(
    'WHEN autoDispose is false'
    'THEN controller is preserved'
    'CASE TextField with no form nor listeners',
    (tester) async {
      final name = RM.injectTextEditing(
        autoDispose: false,
      );
      final email = RM.injectTextEditing();

      final switcher = true.inj();

      final widget = MaterialApp(
        home: Scaffold(
          body: On(() {
            if (switcher.state) {
              return Column(
                children: [
                  TextField(
                    key: Key('Name'),
                    controller: name.controller,
                    decoration: InputDecoration(errorText: name.error),
                  ),
                  TextField(
                    key: Key('Email'),
                    controller: email.controller,
                    decoration: InputDecoration(errorText: email.error),
                  ),
                ],
              );
            }
            return Container();
          }).listenTo(switcher),
        ),
      );
      await tester.pumpWidget(widget);
      expect(name.text, '');
      expect(email.text, '');
      await tester.enterText(find.byKey(Key('Name')), 'name');
      await tester.enterText(find.byKey(Key('Email')), 'email');
      await tester.pump();
      expect(name.text, 'name');
      expect(email.text, 'email');
      expect(find.text('name'), findsOneWidget);
      expect(find.text('email'), findsOneWidget);
      //
      switcher.toggle();
      await tester.pump();
      switcher.toggle();
      await tester.pump();
      expect(name.text, 'name');
      expect(email.text, '');
      expect(find.text('name'), findsOneWidget);
      expect(find.text('email'), findsNothing);
    },
  );

  testWidgets(
    'WHEN autoDispose is true (default)'
    'AND WHEN injectedEditing controller has no widget listener'
    'THEN it is not disposed if the controller is linked to at least one textField',
    (tester) async {
      final name = RM.injectTextEditing(
        autoDispose: false,
      );

      final switcher = true.inj();

      final widget = MaterialApp(
        home: Scaffold(
          body: On(() {
            return Column(
              children: [
                if (switcher.state)
                  TextField(
                    key: Key('Name'),
                    controller: name.controller,
                    decoration: InputDecoration(errorText: name.error),
                  )
                else
                  Container(),
                TextField(
                  controller: name.controller,
                  decoration: InputDecoration(errorText: email.error),
                ),
              ],
            );
          }).listenTo(switcher),
        ),
      );
      await tester.pumpWidget(widget);
      expect(name.text, '');
      await tester.enterText(find.byKey(Key('Name')), 'name');
      await tester.pump();
      expect(name.text, 'name');
      expect(find.text('name'), findsNWidgets(2));
      //
      switcher.toggle();
      await tester.pump();
      expect(find.text('name'), findsNWidgets(1));

      switcher.toggle();
      await tester.pump();
      expect(name.text, 'name');
      expect(find.text('name'), findsNWidgets(2));
    },
  );

  testWidgets(
    'focusNode works',
    (tester) async {
      final name = RM.injectTextEditing(
        autoDispose: false,
      );

      final widget = MaterialApp(
        home: Scaffold(
          body: On.form(
            () {
              return Column(
                children: [
                  TextField(
                    key: Key('Name'),
                    controller: name.controller,
                    focusNode: name.focusNode,
                    decoration: InputDecoration(errorText: name.error),
                  ),
                  TextField(
                    key: Key('Email'),
                    controller: email.controller,
                    focusNode: email.focusNode,
                    decoration: InputDecoration(errorText: email.error),
                  ),
                ],
              );
            },
          ).listenTo(form),
        ),
      );
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();
      email.focusNode.requestFocus();
      await tester.pumpAndSettle();
      name.focusNode.requestFocus();
      await tester.pumpAndSettle();
    },
  );
  testWidgets(
    'WHEN Two form are defined with one has ListView builder'
    'THEN each form get the right associated TextFields',
    (tester) async {
      final form1 = RM.injectForm(
        autovalidateMode: AutovalidateMode.always,
      );
      final form2 = RM.injectForm(
        autovalidateMode: AutovalidateMode.always,
      );

      final textField1 = RM.injectTextEditing(
        validators: [(_) => 'TextField1 Error'],
      );
      final textField2 = RM.injectTextEditing(
        validators: [(_) => 'TextField2 Error'],
      );
      final widget = MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              SizedBox(
                height: 100,
                child: ListView.builder(
                  itemCount: 1,
                  itemBuilder: (_, __) {
                    return Builder(
                      builder: (_) {
                        return On.form(
                          () {
                            return TextField(
                              key: Key('TextField1'),
                              controller: textField1.controller,
                              decoration: InputDecoration(
                                errorText: textField1.error,
                              ),
                            );
                          },
                        ).listenTo(form1);
                      },
                    );
                  },
                ),
              ),
              On.form(
                () => TextField(
                  key: Key('TextField2'),
                  controller: textField2.controller,
                  decoration: InputDecoration(
                    errorText: textField2.error,
                  ),
                ),
              ).listenTo(form2),
            ],
          ),
        ),
      );

      await tester.pumpWidget(widget);
      await tester.pump();
      expect(find.text('TextField1 Error'), findsOneWidget);
      expect(find.text('TextField2 Error'), findsOneWidget);
      //
      await tester.enterText(find.byKey(Key('TextField1')), 'Field 1');
      await tester.enterText(find.byKey(Key('TextField2')), 'Field 2');
      await tester.pump();
      expect(find.text('Field 1'), findsOneWidget);
      expect(find.text('Field 2'), findsOneWidget);
      form1.reset();
      await tester.pump();
      expect(find.text('Field 1'), findsNothing);
      expect(find.text('Field 2'), findsOneWidget);
      form2.reset();
      await tester.pump();
      expect(find.text('Field 1'), findsNothing);
      expect(find.text('Field 2'), findsNothing);
      //
      await tester.enterText(find.byKey(Key('TextField1')), 'Field 1');
      await tester.enterText(find.byKey(Key('TextField2')), 'Field 2');
      await tester.pump();
      expect(find.text('Field 1'), findsOneWidget);
      expect(find.text('Field 2'), findsOneWidget);
      form2.reset();
      await tester.pump();
      expect(find.text('Field 1'), findsOneWidget);
      expect(find.text('Field 2'), findsNothing);
      form1.reset();
      await tester.pump();
      expect(find.text('Field 1'), findsNothing);
      expect(find.text('Field 2'), findsNothing);
    },
  );

  testWidgets(
    'On.formSubmission widget and side effects work',
    (tester) async {
      final name = RM.injectTextEditing(
        validateOnLoseFocus: false,
      );
      final email = RM.injectTextEditing(
        validateOnTyping: false,
      );
      String submitMessage = '';
      String? serverError = 'Server Error';
      late void Function() refresher;
      final form = RM.injectForm(
        // autoFocusOnFirstError: false,
        submit: () async {
          await Future.delayed(Duration(seconds: 1));
          email.error = 'Email Server Error';
        },
        onSubmitting: () => submitMessage = 'Submitting...',
        onSubmitted: () => submitMessage = 'Submitted',
      );

      final widget = MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              form.rebuild.onForm(
                () {
                  return Column(
                    children: [
                      TextField(
                        key: Key('Name'),
                        controller: name.controller,
                        focusNode: name.focusNode,
                        decoration: InputDecoration(errorText: name.error),
                      ),
                      TextField(
                        key: Key('Email'),
                        controller: email.controller,
                        focusNode: email.focusNode,
                        decoration: InputDecoration(errorText: email.error),
                      ),
                      form.rebuild.onFormSubmission(
                        onSubmitting: () => Text('Submitting...'),
                        onSubmissionError: (error, ref) {
                          refresher = ref;
                          return Text(error);
                        },
                        child: ElevatedButton(
                          onPressed: () {
                            form.submit();
                          },
                          child: Text('Submit1'),
                        ),
                      ),
                    ],
                  );
                },
              ),
              On.formSubmission(
                onSubmitting: () => Text('Submitting...'),
                child: ElevatedButton(
                  onPressed: () {
                    form.submit(
                      () async {
                        await Future.delayed(Duration(seconds: 1));
                        if (serverError != null) throw serverError;
                      },
                    );
                  },
                  child: Text('Submit2'),
                ),
              ).listenTo(form),
            ],
          ),
        ),
      );
      await tester.pumpWidget(widget);
      expect(submitMessage, '');
      expect(find.text('Email Server Error'), findsNothing);
      expect(find.text('Submit1'), findsOneWidget);
      expect(find.text('Submit2'), findsOneWidget);
      //
      await tester.tap(find.text('Submit1'));
      await tester.pump();
      expect(find.text('Email Server Error'), findsNothing);
      expect(find.text('Submit1'), findsNothing);
      expect(find.text('Submit2'), findsNothing);
      expect(submitMessage, 'Submitting...');
      expect(find.text('Submitting...'), findsNWidgets(2));

      await tester.pump(Duration(seconds: 1));
      expect(find.text('Email Server Error'), findsOneWidget);
      expect(find.text('Submit1'), findsOneWidget);
      expect(find.text('Submit2'), findsOneWidget);
      expect(submitMessage, 'Submitted');
      expect(find.text('Submitting...'), findsNothing);
      //
      await tester.tap(find.text('Submit2'));
      await tester.pump();
      expect(find.text('Email Server Error'), findsNothing);
      expect(find.text('Submit1'), findsNothing);
      expect(find.text('Submit2'), findsNothing);
      expect(submitMessage, 'Submitting...');
      expect(find.text('Submitting...'), findsNWidgets(2));

      //
      await tester.pump(Duration(seconds: 1));
      expect(find.text('Email Server Error'), findsNothing);
      expect(find.text('Server Error'), findsOneWidget);
      expect(find.text('Submit2'), findsOneWidget);
      expect(find.text('Submitting...'), findsNothing);
      serverError = null;
      refresher();
      await tester.pump();
      expect(find.text('Email Server Error'), findsNothing);
      expect(find.text('Submit1'), findsNothing);
      expect(find.text('Submit2'), findsNothing);
      expect(submitMessage, 'Submitting...');
      expect(find.text('Submitting...'), findsNWidgets(2));

      //
      await tester.pump(Duration(seconds: 1));
      expect(find.text('Email Server Error'), findsNothing);
      expect(find.text('Server Error'), findsNothing);
      expect(find.text('Submit1'), findsOneWidget);
      expect(find.text('Submit2'), findsOneWidget);
      expect(find.text('Submitting...'), findsNothing);
    },
  );

  testWidgets(
    'On.formSubmission widget and side effects work for OnFormFieldBuilder',
    (tester) async {
      final name = RM.injectFormField<String>(
        '',
        validateOnLoseFocus: false,
      );
      final email = RM.injectFormField<String>(
        '',
        validateOnLoseFocus: false,
      );
      String submitMessage = '';
      String? serverError = 'Server Error';
      late void Function() refresher;
      final form = RM.injectForm(
        // autoFocusOnFirstError: false,
        submit: () async {
          await Future.delayed(Duration(seconds: 1));
          email.error = 'Email Server Error';
        },
        onSubmitting: () => submitMessage = 'Submitting...',
        onSubmitted: () => submitMessage = 'Submitted',
      );

      final widget = MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              OnFormBuilder(
                listenTo: form,
                builder: () {
                  return Column(
                    children: [
                      OnFormFieldBuilder<String>(
                        listenTo: name,
                        builder: (value) {
                          return TextFormField(
                            key: Key('Name'),
                            initialValue: value,
                            onChanged: name.onChanged,
                          );
                        },
                      ),
                      OnFormFieldBuilder<String>(
                        listenTo: email,
                        builder: (value) {
                          return TextFormField(
                            key: Key('Email'),
                            initialValue: value,
                            onChanged: name.onChanged,
                          );
                        },
                      ),
                      form.rebuild.onFormSubmission(
                        onSubmitting: () => Text('Submitting...'),
                        onSubmissionError: (error, ref) {
                          refresher = ref;
                          return Text(error);
                        },
                        child: ElevatedButton(
                          onPressed: () {
                            form.submit();
                          },
                          child: Text('Submit1'),
                        ),
                      ),
                    ],
                  );
                },
              ),
              On.formSubmission(
                onSubmitting: () => Text('Submitting...'),
                child: ElevatedButton(
                  onPressed: () {
                    form.submit(
                      () async {
                        await Future.delayed(Duration(seconds: 1));
                        if (serverError != null) throw serverError;
                      },
                    );
                  },
                  child: Text('Submit2'),
                ),
              ).listenTo(form),
            ],
          ),
        ),
      );
      await tester.pumpWidget(widget);
      expect(submitMessage, '');
      expect(find.text('Email Server Error'), findsNothing);
      expect(find.text('Submit1'), findsOneWidget);
      expect(find.text('Submit2'), findsOneWidget);
      //
      await tester.tap(find.text('Submit1'));
      await tester.pump();
      expect(find.text('Email Server Error'), findsNothing);
      expect(find.text('Submit1'), findsNothing);
      expect(find.text('Submit2'), findsNothing);
      expect(submitMessage, 'Submitting...');
      expect(find.text('Submitting...'), findsNWidgets(2));

      await tester.pump(Duration(seconds: 1));
      expect(find.text('Email Server Error'), findsOneWidget);
      expect(find.text('Submit1'), findsOneWidget);
      expect(find.text('Submit2'), findsOneWidget);
      expect(submitMessage, 'Submitted');
      expect(find.text('Submitting...'), findsNothing);
      //
      await tester.tap(find.text('Submit2'));
      await tester.pump();
      expect(find.text('Email Server Error'), findsNothing);
      expect(find.text('Submit1'), findsNothing);
      expect(find.text('Submit2'), findsNothing);
      expect(submitMessage, 'Submitting...');
      expect(find.text('Submitting...'), findsNWidgets(2));

      //
      await tester.pump(Duration(seconds: 1));
      expect(find.text('Email Server Error'), findsNothing);
      expect(find.text('Server Error'), findsOneWidget);
      expect(find.text('Submit2'), findsOneWidget);
      expect(find.text('Submitting...'), findsNothing);
      serverError = null;
      refresher();
      await tester.pump();
      expect(find.text('Email Server Error'), findsNothing);
      expect(find.text('Submit1'), findsNothing);
      expect(find.text('Submit2'), findsNothing);
      expect(submitMessage, 'Submitting...');
      expect(find.text('Submitting...'), findsNWidgets(2));

      //
      await tester.pump(Duration(seconds: 1));
      expect(find.text('Email Server Error'), findsNothing);
      expect(find.text('Server Error'), findsNothing);
      expect(find.text('Submit1'), findsOneWidget);
      expect(find.text('Submit2'), findsOneWidget);
      expect(find.text('Submitting...'), findsNothing);
    },
  );

  testWidgets(
    'OnFormBuilder and OnFormSubmissionBuilder ',
    (tester) async {
      final name = RM.injectTextEditing(
        validateOnLoseFocus: false,
      );
      final email = RM.injectTextEditing(
        validateOnTyping: false,
      );
      String submitMessage = '';
      String? serverError = 'Server Error';
      late void Function() refresher;
      final form = RM.injectForm(
        // autoFocusOnFirstError: false,
        submit: () async {
          await Future.delayed(Duration(seconds: 1));
          email.error = 'Email Server Error';
        },
        onSubmitting: () => submitMessage = 'Submitting...',
        onSubmitted: () => submitMessage = 'Submitted',
      );

      final widget = MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              OnFormBuilder(
                listenTo: form,
                builder: () {
                  return Column(
                    children: [
                      TextField(
                        key: Key('Name'),
                        controller: name.controller,
                        focusNode: name.focusNode,
                        decoration: InputDecoration(errorText: name.error),
                      ),
                      TextField(
                        key: Key('Email'),
                        controller: email.controller,
                        focusNode: email.focusNode,
                        decoration: InputDecoration(errorText: email.error),
                      ),
                      OnFormSubmissionBuilder(
                        listenTo: form,
                        onSubmitting: () => Text('Submitting...'),
                        onSubmissionError: (error, ref) {
                          refresher = ref;
                          return Text(error);
                        },
                        child: ElevatedButton(
                          onPressed: () {
                            form.submit();
                          },
                          child: Text('Submit1'),
                        ),
                      ),
                    ],
                  );
                },
              ),
              On.formSubmission(
                onSubmitting: () => Text('Submitting...'),
                child: ElevatedButton(
                  onPressed: () {
                    form.submit(
                      () async {
                        await Future.delayed(Duration(seconds: 1));
                        if (serverError != null) throw serverError;
                      },
                    );
                  },
                  child: Text('Submit2'),
                ),
              ).listenTo(form),
            ],
          ),
        ),
      );
      await tester.pumpWidget(widget);
      expect(submitMessage, '');
      expect(find.text('Email Server Error'), findsNothing);
      expect(find.text('Submit1'), findsOneWidget);
      expect(find.text('Submit2'), findsOneWidget);
      //
      await tester.tap(find.text('Submit1'));
      await tester.pump();
      expect(find.text('Email Server Error'), findsNothing);
      expect(find.text('Submit1'), findsNothing);
      expect(find.text('Submit2'), findsNothing);
      expect(submitMessage, 'Submitting...');
      expect(find.text('Submitting...'), findsNWidgets(2));

      await tester.pump(Duration(seconds: 1));
      expect(find.text('Email Server Error'), findsOneWidget);
      expect(find.text('Submit1'), findsOneWidget);
      expect(find.text('Submit2'), findsOneWidget);
      expect(submitMessage, 'Submitted');
      expect(find.text('Submitting...'), findsNothing);
      //
      await tester.tap(find.text('Submit2'));
      await tester.pump();
      expect(find.text('Email Server Error'), findsNothing);
      expect(find.text('Submit1'), findsNothing);
      expect(find.text('Submit2'), findsNothing);
      expect(submitMessage, 'Submitting...');
      expect(find.text('Submitting...'), findsNWidgets(2));

      //
      await tester.pump(Duration(seconds: 1));
      expect(find.text('Email Server Error'), findsNothing);
      expect(find.text('Server Error'), findsOneWidget);
      expect(find.text('Submit2'), findsOneWidget);
      expect(find.text('Submitting...'), findsNothing);
      serverError = null;
      refresher();
      await tester.pump();
      expect(find.text('Email Server Error'), findsNothing);
      expect(find.text('Submit1'), findsNothing);
      expect(find.text('Submit2'), findsNothing);
      expect(submitMessage, 'Submitting...');
      expect(find.text('Submitting...'), findsNWidgets(2));

      //
      await tester.pump(Duration(seconds: 1));
      expect(find.text('Email Server Error'), findsNothing);
      expect(find.text('Server Error'), findsNothing);
      expect(find.text('Submit1'), findsOneWidget);
      expect(find.text('Submit2'), findsOneWidget);
      expect(find.text('Submitting...'), findsNothing);
    },
  );

  testWidgets(
    'WHEN  TextField is removed'
    'THEN it will be removed from form text fields list',
    (tester) async {
      final form = RM.injectForm();
      final password = RM.injectTextEditing(text: '12');
      final confirmPassword = RM.injectTextEditing(
        validators: [
          (text) {
            if (text != password.state) {
              return 'Password do not match';
            }
          }
        ],
      );

      final isRegister = true.inj();

      final widget = MaterialApp(
        home: Scaffold(
          body: OnReactive(
            () => OnFormBuilder(
              listenTo: form,
              builder: () {
                return Column(
                  children: [
                    TextField(
                      controller: password.controller,
                    ),
                    if (isRegister.state)
                      TextField(
                        controller: confirmPassword.controller,
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpWidget(widget);
      expect(form.isValid, false);
      isRegister.toggle();
      await tester.pump();
      expect(form.isValid, true);
    },
  );

  testWidgets(
    'WHEN a field is autoFocused'
    'THEN the it is assigned to the form autoFocusedNode'
    'AND it is auto validated when lost focus',
    (tester) async {
      final text = RM
          .injectTextEditing(text: '', validateOnLoseFocus: true, validators: [
        (txt) {
          if (txt!.length < 3) {
            return 'not allowed';
          }
        }
      ]);
      final form = RM.injectForm();
      final widget = MaterialApp(
        home: Scaffold(
          body: OnFormBuilder(
            listenTo: form,
            builder: () {
              return Column(
                children: [
                  OnReactive(
                    () => TextField(
                      focusNode: text.focusNode,
                      controller: text.controller,
                      autofocus: true,
                      decoration: InputDecoration(
                        errorText: text.error,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    focusNode: form.submitFocusNode,
                    onPressed: () {},
                    child: Text('Submit'),
                  ),
                ],
              );
            },
          ),
        ),
      );
      await tester.pumpWidget(widget);
      expect((form as InjectedFormImp).autoFocusedNode, isNotNull);
      expect(find.text('not allowed'), findsNothing);
      form.submitFocusNode.requestFocus();
      await tester.pump();
      expect(find.text('not allowed'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, '1');
      await tester.pump();
      expect(find.text('not allowed'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, '12');
      await tester.pump();
      expect(find.text('not allowed'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, '123');
      await tester.pump();
      expect(find.text('123'), findsOneWidget);
      //
      await tester.enterText(find.byType(TextField).first, '');
      await tester.pump();
      expect(find.text('not allowed'), findsOneWidget);
      //
      form.reset();
      await tester.pump();
      expect(find.text('not allowed'), findsNothing);
      //
      form.submitFocusNode.requestFocus();
      await tester.pump();
      expect(find.text('not allowed'), findsOneWidget);
      //
      text.reset();
      await tester.pump();
      expect(find.text('not allowed'), findsNothing);
    },
  );

  testWidgets(
    'Check TextField validation and reset without form',
    (tester) async {
      final text1 =
          RM.injectTextEditing(text: 'initial text1', validateOnTyping: false);
      final text2 = RM.injectTextEditing(text: 'initial text2', validators: [
        (txt) {
          if (txt!.length < 3) return 'not allowed';
        }
      ]);
      final widget = MaterialApp(
        home: Scaffold(
          body: OnReactive(
            () => Column(
              children: [
                Text(text1.text),
                Text(text2.text),
                TextField(
                  controller: text1.controller,
                ),
                TextField(
                  controller: text2.controller,
                  decoration: InputDecoration(
                    errorText: text2.error,
                  ),
                ),
              ],
            ),
            debugPrintWhenObserverAdd: '',
          ),
        ),
      );
      await tester.pumpWidget(widget);
      expect(find.text('initial text1'), findsNWidgets(2));
      expect(find.text('initial text2'), findsNWidgets(2));
      //
      expect(text1.isValid, true);
      await tester.enterText(find.byType(TextField).first, 'new text1');
      await tester.pump();
      expect(find.text('new text1'), findsNWidgets(2));
      expect(text1.isValid, true);
      text1.reset();
      await tester.pump();
      expect(find.text('initial text1'), findsNWidgets(2));
      expect(text1.isValid, true);
      //
      expect(text2.isValid, false);
      await tester.enterText(find.byType(TextField).last, 'ne');
      await tester.pump();
      expect(find.text('ne'), findsNWidgets(2));
      expect(find.text('not allowed'), findsOneWidget);
      expect(text2.isValid, false);
      text2.reset();
      await tester.pump();
      expect(find.text('initial text1'), findsNWidgets(2));
      expect(find.text('initial text2'), findsNWidgets(2));
      expect(text2.isValid, false);
    },
  );

  testWidgets(
    'Check when the field is focused and unfocused'
    'THEN the decorator get the right state',
    (tester) async {
      final form = RM.injectForm();
      final checkBox = RM.injectFormField<bool?>(null);
      bool? value;
      final widget = MaterialApp(
        home: Scaffold(
          body: OnFormBuilder(
            listenTo: form,
            builder: () {
              return Column(
                children: [
                  OnFormFieldBuilder<bool?>(
                    listenTo: checkBox,
                    autofocus: true,
                    inputDecoration: InputDecoration(
                      hintText: 'Hint text',
                      labelText: 'Label text',
                      helperText: 'Helper text',
                    ),
                    builder: (v) {
                      value = v;
                      return CheckboxListTile(
                        tristate: true,
                        value: v,
                        onChanged: checkBox.onChanged,
                        title: Text('Text'),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),
      );
      await tester.pumpWidget(widget);
      await tester.pump();
      expect(value, null);
      expect(find.byType(InputDecorator), findsOneWidget);

      final isFocused = find.byWidgetPredicate(
        (widget) => widget is InputDecorator && widget.isFocused,
      );

      expect(isFocused, findsOneWidget);
      // expect(isCheckBoxFocused, findsOneWidget);
      expect(find.text('Label text'), findsOneWidget);
      expect(find.text('Hint text'), findsOneWidget);
      expect(find.text('Helper text'), findsOneWidget);
      //
      checkBox.focusNode.unfocus();
      await tester.pump();
      await tester.pump();
      expect(isFocused, findsNothing);
      expect(find.text('Label text'), findsOneWidget);
      expect(find.text('Hint text'), findsOneWidget);
      expect(find.text('Helper text'), findsOneWidget);
      //
      checkBox.focusNode.requestFocus();
      await tester.pump();
      expect(isFocused, findsOneWidget);
      expect(find.text('Label text'), findsOneWidget);
      expect(find.text('Hint text'), findsOneWidget);
      expect(find.text('Helper text'), findsOneWidget);
      //
      await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(value, false);
    },
  );

  testWidgets(
    'WHEN initial value of injectedForm is null'
    'THEN the label text is displayed'
    'AND WHEN the value is set to non null'
    'THEN label and hint text '
    'THEN',
    (tester) async {
      final form = RM.injectForm();
      final checkBox = RM.injectFormField<bool?>(
        null,
        validators: [
          (value) {
            if (value == null || !value) {
              return 'You must check me';
            }
          },
        ],
      );
      bool? value;
      final widget = MaterialApp(
        home: Scaffold(
          body: OnFormBuilder(
            listenTo: form,
            builder: () {
              return Column(
                children: [
                  OnFormFieldBuilder<bool?>(
                    listenTo: checkBox,
                    inputDecoration: InputDecoration(
                      hintText: 'Hint text',
                      labelText: 'Label text',
                      helperText: 'Helper text',
                    ),
                    builder: (v) {
                      value = v;
                      return Checkbox(
                        tristate: true,
                        value: v,
                        onChanged: checkBox.onChanged,
                      );
                    },
                  )
                ],
              );
            },
          ),
        ),
      );
      await tester.pumpWidget(widget);
      expect(value, null);
      expect(find.byType(InputDecorator), findsOneWidget);
      final isEmptyInput = find.byWidgetPredicate(
        (widget) => widget is InputDecorator && widget.isEmpty,
      );
      final isFocused = find.byWidgetPredicate(
        (widget) => widget is InputDecorator && widget.isFocused,
      );
      expect(isEmptyInput, findsOneWidget);
      expect(isFocused, findsNothing);
      expect(find.text('Label text'), findsOneWidget);
      expect(find.text('Hint text'), findsOneWidget);
      expect(find.text('Helper text'), findsOneWidget);

      checkBox.focusNode.requestFocus();
      await tester.pump();
      expect(isEmptyInput, findsOneWidget);
      expect(isFocused, findsOneWidget);
      expect(find.text('Label text'), findsOneWidget);
      expect(find.text('Hint text'), findsOneWidget);
      expect(find.text('Helper text'), findsOneWidget);
      //
      checkBox.focusNode.unfocus();
      await tester.pump();
      expect(isEmptyInput, findsOneWidget);
      expect(isFocused, findsNothing);
      expect(find.text('Label text'), findsOneWidget);
      expect(find.text('Hint text'), findsOneWidget);
      expect(find.text('Helper text'), findsOneWidget);
      //
      checkBox.value = true;
      await tester.pump();
      expect(value, true);
      expect(isEmptyInput, findsNothing);
      expect(find.text('Label text'), findsOneWidget);
      expect(find.text('Hint text'), findsOneWidget);
      expect(find.text('Helper text'), findsOneWidget);
      //
      form.reset();
      await tester.pump();
      expect(value, null);
      expect(form.validate(), false);
      await tester.pump();
      expect(find.text('You must check me'), findsOneWidget);
      //
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      expect(value, false);
      expect(form.validate(), false);
      //
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      expect(value, true);
      expect(form.validate(), true);
      //
    },
  );
}

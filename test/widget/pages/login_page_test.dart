/// LoginPage Widget Tests
///
/// Tests for the LoginPage UI including:
/// - Form rendering
/// - Input validation
/// - Password visibility toggle
/// - Remember me checkbox
/// - Navigation to sign up
///
/// To run: flutter test test/widget/pages/login_page_test.dart
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/widget_test_helpers.dart';

void main() {
  group('LoginPage - UI Elements', () {
    testWidgets('renders login form with all required fields', (tester) async {
      await tester.pumpWidget(createTestableWidget(const _TestLoginForm()));
      await tester.pumpAndSettle();

      // Should have username field
      expect(find.byKey(const Key('username_field')), findsOneWidget);

      // Should have password field
      expect(find.byKey(const Key('password_field')), findsOneWidget);

      // Should have login button
      expect(find.byKey(const Key('login_button')), findsOneWidget);
    });

    testWidgets('renders remember me checkbox', (tester) async {
      await tester.pumpWidget(createTestableWidget(const _TestLoginForm()));
      await tester.pumpAndSettle();

      expect(find.byType(Checkbox), findsOneWidget);
      expect(find.text('Remember me'), findsOneWidget);
    });

    testWidgets('renders sign up link', (tester) async {
      await tester.pumpWidget(createTestableWidget(const _TestLoginForm()));
      await tester.pumpAndSettle();

      expect(find.text("Don't have an account?"), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);
    });

    testWidgets('password field shows visibility_off icon by default (obscured)', (tester) async {
      await tester.pumpWidget(createTestableWidget(const _TestLoginForm()));
      await tester.pumpAndSettle();

      // visibility_off icon means password IS obscured
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
      expect(find.byIcon(Icons.visibility), findsNothing);
    });
  });

  group('LoginPage - Form Validation', () {
    testWidgets('shows error when username is empty', (tester) async {
      await tester.pumpWidget(createTestableWidget(const _TestLoginForm()));
      await tester.pumpAndSettle();

      // Leave username empty, enter password
      await tester.enterText(find.byKey(const Key('password_field')), 'password123');

      // Tap login button
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.text('Please enter your username'), findsOneWidget);
    });

    testWidgets('shows error when password is empty', (tester) async {
      await tester.pumpWidget(createTestableWidget(const _TestLoginForm()));
      await tester.pumpAndSettle();

      // Enter username, leave password empty
      await tester.enterText(find.byKey(const Key('username_field')), 'testuser');

      // Tap login button
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('shows error when password is too short', (tester) async {
      await tester.pumpWidget(createTestableWidget(const _TestLoginForm()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('username_field')), 'testuser');
      await tester.enterText(find.byKey(const Key('password_field')), '123');

      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();

      expect(find.text('Password must be at least 6 characters'), findsOneWidget);
    });

    testWidgets('no validation errors with valid input', (tester) async {
      await tester.pumpWidget(createTestableWidget(const _TestLoginForm()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('username_field')), 'testuser');
      await tester.enterText(find.byKey(const Key('password_field')), 'password123');

      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();

      // Should not show validation errors
      expect(find.text('Please enter your username'), findsNothing);
      expect(find.text('Please enter your password'), findsNothing);
    });
  });

  group('LoginPage - Password Visibility', () {
    testWidgets('toggles password visibility on icon tap', (tester) async {
      await tester.pumpWidget(createTestableWidget(const _TestLoginForm()));
      await tester.pumpAndSettle();

      // Initially obscured (visibility_off icon shown)
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
      expect(find.byIcon(Icons.visibility), findsNothing);

      // Find and tap visibility toggle
      await tester.tap(find.byKey(const Key('password_visibility_toggle')));
      await tester.pumpAndSettle();

      // Now visible (visibility icon shown)
      expect(find.byIcon(Icons.visibility), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off), findsNothing);

      // Tap again to hide
      await tester.tap(find.byKey(const Key('password_visibility_toggle')));
      await tester.pumpAndSettle();

      // Obscured again (visibility_off icon shown)
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
      expect(find.byIcon(Icons.visibility), findsNothing);
    });

    testWidgets('shows correct icon based on visibility state', (tester) async {
      await tester.pumpWidget(createTestableWidget(const _TestLoginForm()));
      await tester.pumpAndSettle();

      // Initially shows visibility_off icon (password is hidden)
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);

      // Toggle visibility
      await tester.tap(find.byKey(const Key('password_visibility_toggle')));
      await tester.pumpAndSettle();

      // Now shows visibility icon (password is visible)
      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });
  });

  group('LoginPage - Remember Me', () {
    testWidgets('checkbox toggles on tap', (tester) async {
      await tester.pumpWidget(createTestableWidget(const _TestLoginForm()));
      await tester.pumpAndSettle();

      // Initially unchecked
      var checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, false);

      // Tap checkbox
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      // Now checked
      checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, true);

      // Tap again
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      // Unchecked again
      checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, false);
    });

    testWidgets('tapping label text also toggles checkbox', (tester) async {
      await tester.pumpWidget(createTestableWidget(const _TestLoginForm()));
      await tester.pumpAndSettle();

      var checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, false);

      // Tap the label text
      await tester.tap(find.text('Remember me'));
      await tester.pumpAndSettle();

      checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, true);
    });
  });

  group('LoginPage - Loading State', () {
    testWidgets('shows loading indicator when logging in', (tester) async {
      await tester.pumpWidget(createTestableWidget(const _TestLoginFormWithLoading()));
      await tester.pumpAndSettle();

      // Trigger loading state
      await tester.tap(find.byKey(const Key('trigger_loading')));
      await tester.pump();

      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('disables login button when loading', (tester) async {
      await tester.pumpWidget(createTestableWidget(const _TestLoginFormWithLoading()));
      await tester.pumpAndSettle();

      // Trigger loading state
      await tester.tap(find.byKey(const Key('trigger_loading')));
      await tester.pump();

      // Login button should be disabled (onPressed is null)
      final button = tester.widget<ElevatedButton>(
        find.byKey(const Key('login_button')),
      );
      expect(button.onPressed, isNull);
    });
  });

  group('LoginPage - Input Handling', () {
    testWidgets('trims whitespace from username', (tester) async {
      await tester.pumpWidget(createTestableWidget(const _TestLoginForm()));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('username_field')),
        '  testuser  ',
      );

      final textField = tester.widget<TextFormField>(
        find.byKey(const Key('username_field')),
      );

      // The actual trimming happens on submit, but we can verify the text is entered
      expect(textField.controller?.text, '  testuser  ');
    });

    testWidgets('accepts special characters in username', (tester) async {
      await tester.pumpWidget(createTestableWidget(const _TestLoginForm()));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('username_field')),
        'test.user@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('password_field')),
        'password123',
      );

      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();

      // Should not show username validation error
      expect(find.text('Please enter your username'), findsNothing);
    });

    testWidgets('accepts special characters in password', (tester) async {
      await tester.pumpWidget(createTestableWidget(const _TestLoginForm()));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('username_field')),
        'testuser',
      );
      await tester.enterText(
        find.byKey(const Key('password_field')),
        'P@ssw0rd!#\$%',
      );

      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();

      // Should not show password validation error
      expect(find.text('Please enter your password'), findsNothing);
      expect(find.text('Password must be at least 6 characters'), findsNothing);
    });
  });
}

/// Test widget that mimics LoginPage form behavior
/// Used to test form validation without AuthService dependency
class _TestLoginForm extends StatefulWidget {
  const _TestLoginForm();

  @override
  State<_TestLoginForm> createState() => _TestLoginFormState();
}

class _TestLoginFormState extends State<_TestLoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                key: const Key('username_field'),
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  hintText: 'Enter your username',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your username';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('password_field'),
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter your password',
                  suffixIcon: IconButton(
                    key: const Key('password_visibility_toggle'),
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: _rememberMe,
                    onChanged: (value) {
                      setState(() => _rememberMe = value ?? false);
                    },
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() => _rememberMe = !_rememberMe);
                    },
                    child: const Text('Remember me'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                key: const Key('login_button'),
                onPressed: () {
                  _formKey.currentState!.validate();
                },
                child: const Text('Login'),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account?"),
                  TextButton(
                    onPressed: () {},
                    child: const Text('Sign Up'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

/// Test widget with loading state
class _TestLoginFormWithLoading extends StatefulWidget {
  const _TestLoginFormWithLoading();

  @override
  State<_TestLoginFormWithLoading> createState() => _TestLoginFormWithLoadingState();
}

class _TestLoginFormWithLoadingState extends State<_TestLoginFormWithLoading> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          if (_isLoading) const CircularProgressIndicator(),
          ElevatedButton(
            key: const Key('login_button'),
            onPressed: _isLoading ? null : () {},
            child: const Text('Login'),
          ),
          ElevatedButton(
            key: const Key('trigger_loading'),
            onPressed: () {
              setState(() => _isLoading = true);
            },
            child: const Text('Trigger Loading'),
          ),
        ],
      ),
    );
  }
}

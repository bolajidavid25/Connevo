import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connevo/auth/model/auth_model.dart';

// Using Notifier instead of StateNotifier for Riverpod 2.0+ compatibility
class AuthFormNotifier extends Notifier<AuthFormState> {
  @override
  AuthFormState build() {
    return AuthFormState();
  }

  void togglePasswordVisibility() {
    state = state.copyWith(isPasswordHidden: !state.isPasswordHidden);
  }

  void updateName(String name) {
    String? nameError;
    if (name.isNotEmpty && name.length < 3) {
      nameError = 'Name is too short';
    }
    state = state.copyWith(name: name, nameError: nameError);
  }

  void updateEmail(String email) {
    String? emailError;
    if (email.isNotEmpty && !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      emailError = "Enter a valid email address";
    }
    state = state.copyWith(email: email, emailError: emailError);
  }

  void updatePassword(String password) {
    String? passwordError;
    if (password.isNotEmpty && password.length < 6) {
      passwordError = 'Minimum 6 characters required';
    }
    state = state.copyWith(password: password, passwordError: passwordError);
  }

  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  // Resets the entire form state
  void clear() {
    state = AuthFormState();
  }
}

// Updated Provider definition for Notifier
final authFormProvider = NotifierProvider<AuthFormNotifier, AuthFormState>(
  AuthFormNotifier.new,
);

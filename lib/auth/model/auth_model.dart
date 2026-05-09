class AuthFormState {
  final String name;
  final String email;
  final String password;
  final String? nameError;
  final String? emailError;
  final String? passwordError;
  final bool isLoading;
  final bool isPasswordHidden;

  AuthFormState({
    this.name = "",
    this.email = '',
    this.password = "",
    this.nameError,
    this.emailError,
    this.passwordError,
    this.isLoading = false,
    this.isPasswordHidden = true,
  });

  bool get isSignupValid =>
      name.isNotEmpty &&
      email.isNotEmpty &&
      password.isNotEmpty &&
      nameError == null &&
      emailError == null &&
      passwordError == null;

  bool get isLoginValid =>
      email.isNotEmpty &&
      password.isNotEmpty &&
      emailError == null &&
      passwordError == null;

  AuthFormState copyWith({
    String? name,
    String? email,
    String? password,
    String? nameError,
    String? emailError,
    String? passwordError,
    bool? isLoading,
    bool? isPasswordHidden,
  }) {
    return AuthFormState(
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      nameError: nameError,
      emailError: emailError,
      passwordError: passwordError,
      isLoading: isLoading ?? this.isLoading,
      isPasswordHidden: isPasswordHidden ?? this.isPasswordHidden,
    );
  }
}

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? profilePic;
  final bool isOnline;
  final DateTime? lastSeen;
  final DateTime? createdAt;
  final bool notificationsEnabled; // New field

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.profilePic,
    this.isOnline = false,
    this.lastSeen,
    this.createdAt,
    this.notificationsEnabled = true, // Default to true
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'profilePic': profilePic,
      'isOnline': isOnline,
      'lastSeen': lastSeen?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'notificationsEnabled': notificationsEnabled,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      profilePic: map['profilePic'],
      isOnline: map['isOnline'] ?? false,
      lastSeen: map['lastSeen'] != null ? DateTime.tryParse(map['lastSeen']) : null,
      createdAt: map['createdAt'] != null ? DateTime.tryParse(map['createdAt']) : null,
      notificationsEnabled: map['notificationsEnabled'] ?? true,
    );
  }
}

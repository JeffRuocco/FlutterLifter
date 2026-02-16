import '../config/auth_config.dart';

/// Represents the application user, mapping from Firebase or guest state.
class AppUser {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoURL;
  final AuthProvider authProvider;
  final DateTime createdAt;

  const AppUser({
    required this.uid,
    this.email,
    this.displayName,
    this.photoURL,
    required this.authProvider,
    required this.createdAt,
  });

  /// Whether the user is a guest (local-only, no Firebase account).
  bool get isGuest => authProvider == AuthProvider.guest;

  /// Creates a guest user with deterministic UID.
  factory AppUser.guest() {
    return AppUser(
      uid: 'guest',
      authProvider: AuthProvider.guest,
      createdAt: DateTime.now(),
    );
  }

  /// Serializes the user to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'authProvider': authProvider.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Deserializes a user from a JSON map.
  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      uid: json['uid'] as String,
      email: json['email'] as String?,
      displayName: json['displayName'] as String?,
      photoURL: json['photoURL'] as String?,
      authProvider: AuthProvider.values.firstWhere(
        (e) => e.name == json['authProvider'],
        orElse: () => AuthProvider.email,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Creates a copy with updated fields.
  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    AuthProvider? authProvider,
    DateTime? createdAt,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      authProvider: authProvider ?? this.authProvider,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppUser && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;

  @override
  String toString() {
    return 'AppUser(uid: $uid, email: $email, displayName: $displayName, '
        'provider: ${authProvider.name}, isGuest: $isGuest)';
  }
}

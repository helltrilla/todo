import 'dart:convert';

/// Immutable domain model representing an authenticated user.
/// Supports both local (internal registration) and Supabase email accounts.
class AppUser {
  final String id;
  final String name;
  final String? email;
  final bool isLocal;

  const AppUser({
    required this.id,
    required this.name,
    this.email,
    required this.isLocal,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'email': email,
      'isLocal': isLocal,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String?,
      isLocal: (map['isLocal'] as bool?) ?? true,
    );
  }

  String toJson() => json.encode(toMap());

  factory AppUser.fromJson(String source) =>
      AppUser.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppUser && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

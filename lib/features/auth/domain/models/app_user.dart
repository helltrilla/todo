import 'dart:convert';

/// Immutable domain model representing an authenticated user.
/// Supports both local (internal registration) and Supabase email accounts.
class AppUser {
  final String id;
  final String name;
  final String? email;
  final bool isLocal;
  final String? avatarBase64;

  const AppUser({
    required this.id,
    required this.name,
    this.email,
    required this.isLocal,
    this.avatarBase64,
  });

  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    bool? isLocal,
    String? avatarBase64,
    bool clearAvatar = false,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      isLocal: isLocal ?? this.isLocal,
      avatarBase64: clearAvatar ? null : (avatarBase64 ?? this.avatarBase64),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'email': email,
      'isLocal': isLocal,
      if (avatarBase64 != null) 'avatarBase64': avatarBase64,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String?,
      isLocal: (map['isLocal'] as bool?) ?? true,
      avatarBase64: map['avatarBase64'] as String?,
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

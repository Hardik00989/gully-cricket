class AppUser {
  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
  });
  final String uid, name, email, role;
  bool get isAdmin => role == 'admin';
  factory AppUser.fromMap(String uid, Map<String, dynamic> data) => AppUser(
    uid: uid,
    name: data['name'] as String? ?? '',
    email: data['email'] as String? ?? '',
    role: data['role'] as String? ?? 'user',
  );
}

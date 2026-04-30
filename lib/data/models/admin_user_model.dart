class AdminUserModel {
  final String user;
  final String password;
  final String rol;

  const AdminUserModel({
    required this.user,
    required this.password,
    required this.rol,
  });

  AdminUserModel copyWith({String? user, String? password, String? rol}) {
    return AdminUserModel(
      user: user ?? this.user,
      password: password ?? this.password,
      rol: rol ?? this.rol,
    );
  }

  Map<String, dynamic> toJson() {
    return {'user': user, 'password': password, 'rol': rol};
  }
}

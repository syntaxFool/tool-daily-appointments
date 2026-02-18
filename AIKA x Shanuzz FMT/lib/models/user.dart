class User {
  final String reffid;
  final String name;
  final String token;

  User({
    required this.reffid,
    required this.name,
    required this.token,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      reffid: json['Reffid'] ?? '',
      name: json['Name'] ?? '',
      token: json['Token'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Reffid': reffid,
      'Name': name,
      'Token': token,
    };
  }

  User copyWith({
    String? reffid,
    String? name,
    String? token,
  }) {
    return User(
      reffid: reffid ?? this.reffid,
      name: name ?? this.name,
      token: token ?? this.token,
    );
  }
}

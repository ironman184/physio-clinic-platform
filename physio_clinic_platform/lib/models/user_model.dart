import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String phoneNumber;
  final String name;
  final String? email;
  final String role; // 'patient' | 'physiotherapist'
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.phoneNumber,
    required this.name,
    this.email,
    required this.role,
    required this.createdAt,
  });

  factory UserModel.fromMap(String uid, Map<String, dynamic> map) {
    return UserModel(
      uid: uid,
      phoneNumber: map['phoneNumber'] as String? ?? '',
      name: map['name'] as String? ?? '',
      email: map['email'] as String?,
      role: map['role'] as String? ?? 'patient',
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'phoneNumber': phoneNumber,
        'name': name,
        if (email != null && email!.isNotEmpty) 'email': email,
        'role': role,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  UserModel copyWith({String? name, String? email, String? role}) => UserModel(
        uid: uid,
        phoneNumber: phoneNumber,
        name: name ?? this.name,
        email: email ?? this.email,
        role: role ?? this.role,
        createdAt: createdAt,
      );
}

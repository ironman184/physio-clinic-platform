import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String clinicId;
  final String phoneNumber;
  final String firstName;
  final String lastName;
  final String? email;
  final String gender;
  final DateTime dob;
  final String role;
  final String status;
  final DateTime createdAt;
  final List<String> fcmTokens;

  const UserModel({
    required this.uid,
    required this.clinicId,
    required this.phoneNumber,
    required this.firstName,
    required this.lastName,
    this.email,
    required this.gender,
    required this.dob,
    required this.role,
    required this.status,
    required this.createdAt,
    this.fcmTokens = const [],
  });

  String get fullName => '$firstName $lastName';

  factory UserModel.fromMap(String uid, Map<String, dynamic> map) {
    return UserModel(
      uid: uid,
      clinicId: map['clinicId'] as String? ?? '',
      phoneNumber: map['phoneNumber'] as String? ?? '',
      firstName: map['firstName'] as String? ?? '',
      lastName: map['lastName'] as String? ?? '',
      email: map['email'] as String?,
      gender: map['gender'] as String? ?? '',
      dob: map['dob'] is Timestamp
          ? (map['dob'] as Timestamp).toDate()
          : DateTime.now(),
      role: map['role'] as String? ?? 'patient',
      status: map['status'] as String? ?? 'active',
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      fcmTokens: List<String>.from(map['fcmTokens'] as List? ?? []),
    );
  }

  Map<String, dynamic> toMap() => {
        'clinicId': clinicId,
        'phoneNumber': phoneNumber,
        'firstName': firstName,
        'lastName': lastName,
        if (email != null && email!.isNotEmpty) 'email': email,
        'gender': gender,
        'dob': Timestamp.fromDate(dob),
        'role': role,
        'status': status,
        'createdAt': Timestamp.fromDate(createdAt),
        'fcmTokens': fcmTokens,
      };
}

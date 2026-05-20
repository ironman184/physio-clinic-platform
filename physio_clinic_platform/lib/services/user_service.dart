import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService {
  // Singleton so AuthWrapper and AuthProvider share the same instance.
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collection = 'users';

  Future<bool> userExists(String uid) async {
    final doc = await _db.collection(_collection).doc(uid).get();
    return doc.exists;
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection(_collection).doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromMap(uid, doc.data()!);
  }

  Future<void> createUser(UserModel user) {
    return _db.collection(_collection).doc(user.uid).set(user.toMap());
  }
}

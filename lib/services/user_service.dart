import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'users';

  /// Создание нового пользователя
  Future<void> createUser(User user) async {
    await _firestore.collection(_collection).doc(user.id).set(user.toJson());
  }

  /// Получение пользователя по ID
  Future<User?> getUserById(String userId) async {
    final doc = await _firestore.collection(_collection).doc(userId).get();

    if (doc.exists && doc.data() != null) {
      return User.fromJson(doc.data()!);
    }
    return null;
  }

  /// Получение пользователя по номеру телефона
  Future<User?> getUserByPhone(String phone) async {
    final query = await _firestore
        .collection(_collection)
        .where('phone', isEqualTo: phone)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return User.fromJson(query.docs.first.data());
    }
    return null;
  }

  /// Обновление данных пользователя
  Future<void> updateUser(User user) async {
    await _firestore.collection(_collection).doc(user.id).update(user.toJson());
  }

  /// Обновление FCM токена для push-уведомлений
  Future<void> updateFCMToken(String userId, String fcmToken) async {
    await _firestore.collection(_collection).doc(userId).update({
      'fcmToken': fcmToken,
    });
  }

  /// Получение всех диспетчеров
  Future<List<User>> getDispatchers() async {
    final query = await _firestore
        .collection(_collection)
        .where('userType', isEqualTo: UserType.dispatcher.toString())
        .get();

    return query.docs.map((doc) => User.fromJson(doc.data())).toList();
  }

  /// Удаление пользователя
  Future<void> deleteUser(String userId) async {
    await _firestore.collection(_collection).doc(userId).delete();
  }
}

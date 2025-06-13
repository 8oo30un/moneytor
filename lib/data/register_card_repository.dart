import '../model/register_card_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterCardRepository {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // 유저 ID 필요 - 생성자에서 받도록 수정
  final String userId;

  RegisterCardRepository({required this.userId});

  String get collectionPath => 'users/$userId/register_cards';

  Future<List<RegisterCardModel>> fetchRegisterCards() async {
    final snapshot = await firestore.collection(collectionPath).get();
    return snapshot.docs
        .map((doc) => RegisterCardModel.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  Future<void> addRegisterCard(RegisterCardModel card) async {
    await firestore.collection(collectionPath).add(card.toFirestore());
  }

  Future<void> updateRegisterCard(RegisterCardModel card) async {
    await firestore
        .collection(collectionPath)
        .doc(card.id)
        .update(card.toFirestore());
  }

  Future<void> deleteRegisterCard(String id) async {
    await firestore.collection(collectionPath).doc(id).delete();
  }

  Future<void> updateDefaultGoal(int goal) async {
    await firestore.collection('users').doc(userId).set({
      'defaultGoal': goal,
    }, SetOptions(merge: true));
  }

  Future<int> getDefaultGoal() async {
    final doc = await firestore.collection('users').doc(userId).get();
    if (doc.exists && doc.data()!.containsKey('defaultGoal')) {
      return doc.data()!['defaultGoal'] as int;
    } else {
      return 0; // 또는 기본값
    }
  }

  Future<Map<String, int>> fetchUserGoals() async {
    print('Fetching user goals for userId: $userId');
    int totalSpending = 0;
    final doc = await firestore.collection('users').doc(userId).get();

    if (doc.exists) {
      final data = doc.data();
      final int monthlyGoal = data?['defaultGoal'] ?? 0;

      // register_cards 하위 컬렉션 불러오기
      final cardsSnapshot =
          await firestore
              .collection('users')
              .doc(userId)
              .collection('register_cards')
              .get();

      for (final cardDoc in cardsSnapshot.docs) {
        final cardData = cardDoc.data();
        if (cardData.containsKey('totalAmount')) {
          totalSpending += (cardData['totalAmount'] as int? ?? 0);
        }
      }

      print(
        'Fetched monthlyGoal: $monthlyGoal, calculated todaySpending: $totalSpending',
      );
      return {'monthlyGoal': monthlyGoal, 'todaySpending': totalSpending};
    }

    print('No user goals found, returning defaults');
    return {'monthlyGoal': 0, 'todaySpending': 0};
  }
}

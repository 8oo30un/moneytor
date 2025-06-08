// lib/data/register_card_repository.dart
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
}

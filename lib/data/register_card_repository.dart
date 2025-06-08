import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/register_card_model.dart';

class RegisterCardRepository {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final String collectionName = 'register_cards';

  Future<List<RegisterCardModel>> fetchRegisterCards() async {
    final snapshot = await firestore.collection(collectionName).get();
    return snapshot.docs
        .map((doc) => RegisterCardModel.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  Future<void> addRegisterCard(RegisterCardModel card) async {
    await firestore.collection(collectionName).add(card.toFirestore());
  }

  Future<void> updateRegisterCard(RegisterCardModel card) async {
    await firestore
        .collection(collectionName)
        .doc(card.id)
        .update(card.toFirestore());
  }

  Future<void> deleteRegisterCard(String id) async {
    await firestore.collection(collectionName).doc(id).delete();
  }
}

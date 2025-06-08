// lib/data/register_card_model.dart
class RegisterCardModel {
  final String id;
  final String name;
  final int totalAmount;
  final List<Map<String, dynamic>> expenses;

  RegisterCardModel({
    required this.id,
    required this.name,
    required this.totalAmount,
    required this.expenses,
  });

  factory RegisterCardModel.fromFirestore(
    Map<String, dynamic> data,
    String docId,
  ) {
    return RegisterCardModel(
      id: docId,
      name: data['name'] ?? '',
      totalAmount: data['totalAmount'] ?? 0,
      expenses: List<Map<String, dynamic>>.from(data['expenses'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {'name': name, 'totalAmount': totalAmount, 'expenses': expenses};
  }

  RegisterCardModel copyWith({
    String? id,
    String? name,
    int? totalAmount,
    List<Map<String, dynamic>>? expenses,
  }) {
    return RegisterCardModel(
      id: id ?? this.id,
      name: name ?? this.name,
      totalAmount: totalAmount ?? this.totalAmount,
      expenses: expenses ?? this.expenses,
    );
  }
}

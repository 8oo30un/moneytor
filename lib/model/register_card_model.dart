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
}

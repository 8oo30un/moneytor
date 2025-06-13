class RegisterCardModel {
  final String id;
  final String name;
  final int totalAmount;

  final List<Map<String, dynamic>> expenses;
  final int? spendingGoal; // 목표 지출 (nullable)

  RegisterCardModel({
    required this.id,
    required this.name,
    required this.totalAmount,
    required this.expenses,
    this.spendingGoal,
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
      spendingGoal: data['spendingGoal'],
    );
  }

  factory RegisterCardModel.empty() {
    return RegisterCardModel(
      id: '',
      name: '',
      totalAmount: 0,
      expenses: [],
      spendingGoal: 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'totalAmount': totalAmount,
      'expenses': expenses,
      'spendingGoal': spendingGoal,
    };
  }

  RegisterCardModel copyWith({
    String? id,
    String? name,
    int? totalAmount,
    List<Map<String, dynamic>>? expenses,
    int? spendingGoal,
    String? spendingStatus,
  }) {
    return RegisterCardModel(
      id: id ?? this.id,
      name: name ?? this.name,
      totalAmount: totalAmount ?? this.totalAmount,
      expenses: expenses ?? this.expenses,
      spendingGoal: spendingGoal ?? this.spendingGoal,
    );
  }

  static int calculateTotalSpending(List<RegisterCardModel> cards) {
    return cards.fold(0, (sum, card) => sum + card.totalAmount);
  }
}

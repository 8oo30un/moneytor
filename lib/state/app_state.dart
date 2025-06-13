import 'package:flutter/material.dart';
import '../model/register_card_model.dart';
import '../utils/spending_calculator.dart';

class AppState extends ChangeNotifier {
  String userName = '';
  String? photoUrl;
  int monthlyGoal = 0;
  int todaySpending = 0;
  RegisterCardModel? selectedCard;
  List<RegisterCardModel> registerCards = [];
  Color _statusColor = Colors.grey;
  Color get statusColor => _statusColor;

  void setStatusColor(Color color) {
    _statusColor = color;
    notifyListeners();
  }

  void setUser(String name, String? photo) {
    userName = name;
    photoUrl = photo;
    notifyListeners();
  }

  void setMonthlyGoal(int goal) {
    monthlyGoal = goal;
    notifyListeners();
  }

  void setTodaySpending(int spending) {
    todaySpending = spending;
    notifyListeners();
  }

  void setRegisterCards(List<RegisterCardModel> cards) {
    registerCards = cards;
    notifyListeners();
  }

  void selectCard(RegisterCardModel? card) {
    selectedCard = card;
    notifyListeners();
  }

  void updateCard(RegisterCardModel card) {
    final index = registerCards.indexWhere((c) => c.id == card.id);
    if (index != -1) {
      registerCards[index] = card;
      if (selectedCard?.id == card.id) {
        selectedCard = card;
      }
      final status = calculateSpendingStatus(
        monthlyGoal: card.spendingGoal ?? monthlyGoal,
        todaySpending: card.totalAmount,
      );
      _statusColor = status.color;
      notifyListeners();
    }
  }

  void deleteCard(int index) {
    final deleted = registerCards[index];
    registerCards.removeAt(index);
    if (selectedCard?.id == deleted.id) {
      selectedCard = null;
    }
    notifyListeners();
  }
}

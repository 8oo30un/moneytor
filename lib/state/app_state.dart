// lib/state/app_state.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/register_card_model.dart';
import '../data/register_card_repository.dart';

class SpendingStatus {
  final String status;
  final Color color;
  SpendingStatus(this.status, this.color);
}

SpendingStatus calculateSpendingStatusNoContext({
  required int goal,
  required int spending,
}) {
  if (goal == 0) {
    return SpendingStatus('미설정', const Color.fromRGBO(247, 247, 249, 1));
  }

  final DateTime todayDate = DateTime.now();
  final int dayPassed = todayDate.day;
  final double dailyGoal = goal / 30;
  final double recommendedSpending = dailyGoal * dayPassed;

  if (spending > recommendedSpending * 1.1) {
    return SpendingStatus('과소비', Color.fromRGBO(255, 187, 135, 1));
  } else if (spending < recommendedSpending * 0.9) {
    return SpendingStatus('절약', Color.fromRGBO(161, 227, 249, 1));
  } else {
    return SpendingStatus('평균', Color.fromRGBO(152, 219, 204, 1));
  }
}

class AppState extends ChangeNotifier {
  // 사용자 정보
  String _userName = '';
  String? _photoUrl;

  // 목표 및 지출
  int _defaultGoal = 0;
  int _monthlyGoal = 0;
  int _todaySpending = 0;
  int _totalSpending = 0;
  int _recommendedSpending = 0;

  // 카드 관련
  RegisterCardModel? _selectedCard;

  List<RegisterCardModel> _registerCards = [];

  // UI 상태
  Color _statusColor = Colors.grey;
  bool _isEditing = false;
  bool _isLoading = false;

  // Repository
  late RegisterCardRepository _registerCardRepo;

  // Private context for spending status calculation
  BuildContext? _appContext;

  // Getters
  String get userName => _userName;
  String? get photoUrl => _photoUrl;
  int get defaultGoal => 0;
  int get monthlyGoal => _monthlyGoal;
  int get todaySpending => _todaySpending;
  int get totalSpending => _totalSpending;
  int get recommendedSpending => _recommendedSpending;
  RegisterCardModel? get selectedCard => _selectedCard;
  List<RegisterCardModel> get registerCards => _registerCards;
  Color get statusColor => _statusColor;
  bool get isEditing => _isEditing;
  bool get isLoading => _isLoading;

  // Public setters as per simplified class
  void setUser(String name, String? photo) {
    _userName = name;
    _photoUrl = photo;
    notifyListeners();
  }

  Future<void> setMonthlyGoal(int goal) async {
    _monthlyGoal = goal;
    _calculateStatus(); // 👈 상태와 색상 업데이트 추가
    notifyListeners();

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'monthlyGoal': goal,
      });
      print('✅ [setMonthlyGoal] Firestore에 monthlyGoal 업데이트 완료: $goal');
    } catch (e) {
      print('❌ [setMonthlyGoal] Firestore 업데이트 실패: $e');
    }
  }

  void setTodaySpending(int spending) {
    _todaySpending = spending;
    notifyListeners();
  }

  void setRegisterCards(List<RegisterCardModel> cards) {
    _registerCards = cards;
    notifyListeners();
  }

  Future<void> selectCard(RegisterCardModel? card) async {
    _selectedCard = card;
    _calculateStatus(); // context 없이 상태 계산

    _calculateStatus();
    notifyListeners();
  }

  Future<void> updateCard(RegisterCardModel card, BuildContext context) async {
    print(
      '📥 [updateCard] 입력된 카드 ID: ${card.id}, 이름: ${card.name}, 목표지출: ${card.spendingGoal}, 총 지출: ${card.totalAmount}',
    );
    final index = _registerCards.indexWhere((c) => c.id == card.id);
    if (index != -1) {
      _registerCards[index] = card;
      print('✅ [updateCard] 내부 리스트에 카드 업데이트 완료');
      if (_selectedCard?.id == card.id) {
        _selectedCard = card;
      }

      // Firestore 업데이트
      print('📡 [updateCard] Firestore 업데이트 시도 중...');
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final docRef = FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('register_cards')
            .doc(card.id);

        final docSnapshot = await docRef.get();
        if (docSnapshot.exists) {
          await docRef.update({
            'spendingGoal': card.spendingGoal,
            'totalAmount': card.totalAmount,
            'expenses': card.expenses,
            'name': card.name,
          });
          print('✅ [updateCard] 문서 업데이트 완료');
        } else {
          await docRef.set({
            'spendingGoal': card.spendingGoal,
            'totalAmount': card.totalAmount,
            'expenses': card.expenses,
            'name': card.name,
          });
          print('🆕 [updateCard] 문서가 없어서 새로 생성함');
        }
      }

      _calculateStatus();
      print('🔄 [updateCard] 상태 재계산 완료');
      notifyListeners();
    }
  }

  void setStatusColor(Color color) {
    _statusColor = color;
    notifyListeners();
  }

  void setContext(BuildContext context) {
    _appContext = context;
  }

  // 초기화
  void initialize() {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    _registerCardRepo = RegisterCardRepository(userId: userId);
    loadInitialData();
  }

  // 초기 데이터 로드
  Future<void> loadInitialData() async {
    _setLoading(true);
    try {
      await Future.wait([
        _loadUserInfo(),
        _loadDefaultGoal(),
        _loadRegisterCards(),
      ]);
      if (_appContext != null) {
        _calculateStatus();
      }
    } catch (e) {
      print('초기 데이터 로드 실패: $e');
    } finally {
      _setLoading(false);
    }
  }

  // 로딩 상태 설정
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // 편집 모드 토글
  void toggleEditing() {
    _isEditing = !_isEditing;
    notifyListeners();
  }

  // 기본 목표 설정
  Future<void> setDefaultGoal(int goal, BuildContext context) async {
    try {
      _defaultGoal = goal;
      await _saveDefaultGoal(goal);
      _calculateStatus();
      notifyListeners();
    } catch (e) {
      print('기본 목표 설정 실패: $e');
    }
  }

  // 카드 목표 설정
  Future<void> setCardGoal(
    RegisterCardModel card,
    int goal,
    BuildContext context,
  ) async {
    try {
      final updatedCard = card.copyWith(spendingGoal: goal);
      await _registerCardRepo.updateRegisterCard(updatedCard);

      // 리스트에서 해당 카드 업데이트
      final index = _registerCards.indexWhere((c) => c.id == card.id);
      if (index != -1) {
        _registerCards[index] = updatedCard;
      }

      // 선택된 카드가 같다면 업데이트
      if (_selectedCard?.id == card.id) {
        _selectedCard = updatedCard;
      }

      _calculateStatus();
      notifyListeners();
    } catch (e) {
      print('카드 목표 설정 실패: $e');
    }
  }

  // 카드 추가
  Future<void> addCard(String name, BuildContext context) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');

      final cardDocRef =
          FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('register_cards')
              .doc();

      final newCard = RegisterCardModel(
        id: cardDocRef.id,
        name: name,
        totalAmount: 0,
        expenses: [],
        spendingGoal: null,
      );

      print(
        '🆕 [addCard] 새 카드 생성: id=${newCard.id}, name=${newCard.name}, spendingGoal=${newCard.spendingGoal}, totalAmount=${newCard.totalAmount}',
      );

      await cardDocRef.set({
        'name': newCard.name,
        'totalAmount': newCard.totalAmount,
        'expenses': newCard.expenses,
        'spendingGoal': newCard.spendingGoal,
      });
      print('✅ [addCard] Firestore에 새 카드 추가 완료 (ID 자동 생성)');

      _registerCards.add(newCard);
      print('📋 [addCard] 내부 리스트에 새 카드 추가됨. 총 카드 수: ${_registerCards.length}');

      _calculateStatus();
      notifyListeners();
    } catch (e) {
      print('❌ 카드 추가 실패: $e');
    }
  }

  // 카드 삭제 by index
  Future<void> deleteCard(int index, BuildContext context) async {
    try {
      final card = _registerCards[index];
      await _registerCardRepo.deleteRegisterCard(card.id);

      _registerCards.removeAt(index);

      // 선택된 카드가 삭제된 카드라면 선택 해제
      if (_selectedCard?.id == card.id) {
        _selectedCard = null;
      }

      _calculateStatus();
      notifyListeners();
    } catch (e) {
      print('카드 삭제 실패: $e');
    }
  }

  // 카드 이름 수정
  Future<void> updateCardName(String cardId, String newName) async {
    try {
      final index = _registerCards.indexWhere((c) => c.id == cardId);
      if (index == -1) return;

      final updatedCard = _registerCards[index].copyWith(name: newName);
      await _registerCardRepo.updateRegisterCard(updatedCard);

      _registerCards[index] = updatedCard;

      if (_selectedCard?.id == cardId) {
        _selectedCard = updatedCard;
      }

      notifyListeners();
    } catch (e) {
      print('카드 이름 수정 실패: $e');
    }
  }

  // 지출 추가
  Future<void> addExpense(
    String cardId,
    String name,
    int price,
    BuildContext context,
  ) async {
    try {
      final index = _registerCards.indexWhere((c) => c.id == cardId);
      if (index == -1) return;

      final card = _registerCards[index];
      final newExpense = {
        'name': name,
        'price': price,
        'date': DateTime.now().toIso8601String(),
      };

      final updatedExpenses = List<Map<String, dynamic>>.from(card.expenses)
        ..add(newExpense);

      final updatedCard = card.copyWith(
        expenses: updatedExpenses,
        totalAmount: card.totalAmount + price,
      );

      await _registerCardRepo.updateRegisterCard(updatedCard);

      _registerCards[index] = updatedCard;

      if (_selectedCard?.id == cardId) {
        _selectedCard = updatedCard;
      }

      _calculateStatus();
      notifyListeners();
    } catch (e) {
      print('지출 추가 실패: $e');
    }
  }

  // 지출 삭제
  Future<void> deleteExpense(
    String cardId,
    int expenseIndex,
    BuildContext context,
  ) async {
    try {
      final index = _registerCards.indexWhere((c) => c.id == cardId);
      if (index == -1) return;

      final card = _registerCards[index];
      final expenses = List<Map<String, dynamic>>.from(card.expenses);

      if (expenseIndex >= 0 && expenseIndex < expenses.length) {
        final removedExpense = expenses.removeAt(expenseIndex);
        final newTotalAmount =
            card.totalAmount - (removedExpense['price'] as int);

        final updatedCard = card.copyWith(
          expenses: expenses,
          totalAmount: newTotalAmount,
        );

        await _registerCardRepo.updateRegisterCard(updatedCard);

        _registerCards[index] = updatedCard;

        if (_selectedCard?.id == cardId) {
          _selectedCard = updatedCard;
        }

        _calculateStatus();
        notifyListeners();
      }
    } catch (e) {
      print('지출 삭제 실패: $e');
    }
  }

  // 지출 이름 수정
  Future<void> updateExpenseName(
    String cardId,
    int expenseIndex,
    String newName,
  ) async {
    try {
      final index = _registerCards.indexWhere((c) => c.id == cardId);
      if (index == -1) return;

      final card = _registerCards[index];
      final expenses = List<Map<String, dynamic>>.from(card.expenses);

      if (expenseIndex >= 0 && expenseIndex < expenses.length) {
        expenses[expenseIndex] = Map<String, dynamic>.from(
          expenses[expenseIndex],
        )..['name'] = newName;

        final updatedCard = card.copyWith(expenses: expenses);
        await _registerCardRepo.updateRegisterCard(updatedCard);

        _registerCards[index] = updatedCard;

        if (_selectedCard?.id == cardId) {
          _selectedCard = updatedCard;
        }

        notifyListeners();
      }
    } catch (e) {
      print('지출 이름 수정 실패: $e');
    }
  }

  // 상태 계산
  void _calculateStatus() {
    final now = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    final dayOfMonth = now.day;

    int goal = 0;
    int spending = 0;

    if (_selectedCard != null) {
      goal = _selectedCard!.spendingGoal ?? _defaultGoal;
      spending = _selectedCard!.totalAmount;
      print('🔍 Selected card: ${_selectedCard!.name}');
      print('🔍 Selected card goal: $goal');
      print('🔍 Selected card totalAmount: $spending');
    } else {
      goal = _monthlyGoal > 0 ? _monthlyGoal : _defaultGoal;
      spending = RegisterCardModel.calculateTotalSpending(_registerCards);
      print('🔍 No selected card, using all cards total spending');
    }

    final adjustedSpending = (spending / daysInMonth) * dayOfMonth;
    _todaySpending = adjustedSpending.round();
    _totalSpending = RegisterCardModel.calculateTotalSpending(_registerCards);
    final recommended = (goal / daysInMonth) * dayOfMonth;
    _recommendedSpending = recommended.round();

    print('🐥 Total Spending: $_totalSpending');
    print('📌 Recommended Spending: $_recommendedSpending');
    print('🧮 Adjusted Today Spending: $_todaySpending');

    final status = calculateSpendingStatusNoContext(
      goal: goal,
      spending: _todaySpending,
    );
    _statusColor = status.color;

    notifyListeners();
  }

  // Private methods for data loading
  Future<void> _loadUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userName = user.displayName ?? '';
      _photoUrl = user.photoURL;
    }
  }

  Future<void> _loadDefaultGoal() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final doc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (doc.exists) {
      final data = doc.data();
      _monthlyGoal = data?['monthlyGoal'] ?? 0;
      _todaySpending = data?['lastCalculatedSpending'] ?? 0;
      _totalSpending = data?['totalSpending'] ?? 0;
    }
  }

  Future<void> _loadRegisterCards() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final cards = await _registerCardRepo.fetchRegisterCards();
      _registerCards = cards;
    } catch (e) {
      print('카드 로드 실패: $e');
    }
  }

  Future<void> _saveDefaultGoal(int goal) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'defaultGoal': goal,
      'totalSpending': _totalSpending,
      'lastCalculatedSpending': _todaySpending,
    });
  }

  /// Returns the spending status for a card by its id.
  /// If the card is not found, returns 'Unknown'.
  String getCardStatus(String cardId) {
    final card = registerCards.firstWhere(
      (c) => c.id == cardId,
      orElse: () => RegisterCardModel.empty(),
    );
    if (card.id == '') return '미설정';

    final int goal = card.spendingGoal ?? _defaultGoal;
    final int spending = card.totalAmount;

    if (goal == 0) {
      return '미설정';
    }

    final DateTime todayDate = DateTime.now();
    final int dayPassed = todayDate.day;
    final double dailyGoal = goal / 30;
    final double recommendedSpending = dailyGoal * dayPassed;

    if (spending > recommendedSpending * 1.1) {
      return '과소비';
    } else if (spending < recommendedSpending * 0.9) {
      return '절약';
    } else {
      return '평균';
    }
  }

  Color getCardStatusColor(String cardId) {
    try {
      final card = registerCards.firstWhere(
        (c) => c.id == cardId,
        orElse: () => RegisterCardModel.empty(),
      );
      if (card.id == '') {
        return const Color.fromRGBO(247, 247, 249, 1); // 미설정 회색
      }

      final goal = card.spendingGoal ?? defaultGoal;
      // spendingGoal이 0이면 무조건 미설정 색상 반환
      if (goal == 0) {
        return const Color.fromRGBO(247, 247, 249, 1);
      }

      final DateTime todayDate = DateTime.now();
      final int dayPassed = todayDate.day;
      final double dailyGoal = goal / 30;
      final double recommendedSpending = dailyGoal * dayPassed;

      if (card.totalAmount > recommendedSpending * 1.1) {
        return const Color.fromRGBO(255, 187, 135, 1); // 과소비
      } else if (card.totalAmount < recommendedSpending * 0.9) {
        return const Color.fromRGBO(161, 227, 249, 1); // 절약
      } else {
        return const Color.fromRGBO(152, 219, 204, 1); // 평균
      }
    } catch (_) {
      return const Color.fromRGBO(247, 247, 249, 1); // 오류시 미설정 색상 반환
    }
  }

  Future<void> reloadAllData(BuildContext context) async {
    print('🌀 reloadAllData start');

    _setLoading(true);
    notifyListeners();

    try {
      await Future.wait([
        _loadUserInfo(),
        _loadDefaultGoal(),
        _loadRegisterCards(),
      ]);
      print('✅ reloadAllData completed loading all data');
      _calculateStatus();
      await updateTotalSpending(); // ✅ 여기 추가
    } catch (e) {
      print('초기 데이터 로드 실패: $e');
    } finally {
      _setLoading(false);
    }
    notifyListeners();
  }

  Future<void> loadMonthlyGoalFromFirestore() async {
    _setLoading(true);
    notifyListeners();

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      _setLoading(false);
      notifyListeners();
      return;
    }
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();
      if (doc.exists) {
        final data = doc.data();
        _monthlyGoal = data?['monthlyGoal'] ?? 0;
      }
    } catch (e) {
      print('Error loading monthlyGoal: $e');
      _monthlyGoal = 0;
    }

    _setLoading(false);
    notifyListeners();
  }

  Future<void> updateTotalSpending() async {
    print('🔄 [updateTotalSpending] _calculateStatus() 호출');
    _calculateStatus();
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    if (_selectedCard != null) {
      // Debug prints before Firestore update
      print('📡 [updateTotalSpending] 카드 기반 업데이트 시도');
      print('🆔 카드 ID: ${_selectedCard!.id}');
      print('🎯 목표 지출: ${_selectedCard!.spendingGoal}');
      print('💰 총 지출: ${_selectedCard!.totalAmount}');
      final updatedCard = _selectedCard!.copyWith(
        spendingGoal: _selectedCard!.spendingGoal,
      );
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('register_cards')
          .doc(updatedCard.id)
          .update({
            'spendingGoal': updatedCard.spendingGoal ?? 0,
            'totalAmount': updatedCard.totalAmount,
          });
    } else {
      print('📤 Firestore 경로 확인: /users/$userId');
      print('🎯 월간 목표 지출: $_monthlyGoal');
      print('💰 전체 총 지출: $_totalSpending');
      print('📅 오늘 계산된 지출: $_todaySpending');
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId);
      await userRef.update({
        'monthlyGoal': _monthlyGoal,
        'totalSpending': _totalSpending,
        'lastCalculatedSpending': _todaySpending,
      });
      print('✅ 월간 목표 및 지출 Firestore 업데이트 완료');
    }

    print('📦 Firestore 업데이트 완료 후 상태 출력');
    print(
      '✅ Firestore 업데이트됨 ➜ selectedCard: ${_selectedCard?.name}, goal: ${_selectedCard?.spendingGoal ?? _monthlyGoal}, spending: ${_selectedCard?.totalAmount ?? _totalSpending}, today: $_todaySpending',
    );
  }
}

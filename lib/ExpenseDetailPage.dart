import 'package:flutter/material.dart';
import 'model/register_card_model.dart';
import 'data/register_card_repository.dart';

class ExpenseDetailPage extends StatefulWidget {
  final RegisterCardModel card;
  final RegisterCardRepository registerCardRepo;

  const ExpenseDetailPage({
    super.key,
    required this.card,
    required this.registerCardRepo,
  });

  @override
  State<ExpenseDetailPage> createState() => _ExpenseDetailPageState();
}

class _ExpenseDetailPageState extends State<ExpenseDetailPage> {
  late List<Map<String, dynamic>> expenses;
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    expenses = List<Map<String, dynamic>>.from(widget.card.expenses);
  }

  Future<void> _addExpense() async {
    final name = _nameController.text.trim();
    final amount = int.tryParse(_amountController.text.trim()) ?? 0;
    if (name.isEmpty || amount <= 0) return;

    setState(() {
      expenses.add({'name': name, 'price': amount});
    });

    // 총합 계산
    final newTotalAmount = expenses.fold<int>(
      0,
      (sum, expense) => sum + (expense['price'] as int),
    );

    // Firestore에 업데이트
    final updatedCard = RegisterCardModel(
      id: widget.card.id,
      name: widget.card.name,
      expenses: expenses,
      totalAmount: newTotalAmount,
    );

    try {
      await widget.registerCardRepo.updateRegisterCard(updatedCard);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('지출이 추가되었습니다.')));
      _nameController.clear();
      _amountController.clear();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('지출 추가 실패: $e')));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.card.name} 지출 내역')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child:
                  expenses.isEmpty
                      ? const Center(child: Text('지출 내역이 없습니다.'))
                      : ListView.separated(
                        itemCount: expenses.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final expense = expenses[index];
                          return ListTile(
                            title: Text(expense['name']),
                            trailing: Text('${expense['price']}원'),
                          );
                        },
                      ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '지출 이름',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: '가격',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: _addExpense, child: const Text('지출 추가')),
          ],
        ),
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? '이름 정보 없음';
    final photoUrl = user?.photoURL;

    return Scaffold(
      appBar: AppBar(title: const Text('회원 정보')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '사용자',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundImage:
                    photoUrl != null
                        ? NetworkImage(photoUrl)
                        : const AssetImage('assets/userIcon.png')
                            as ImageProvider,
              ),
            ),
            const SizedBox(height: 16),
            Text('이름: $displayName'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: const Text('데이터 초기화 확인'),
                        content: const Text(
                          '이번 달 데이터가 모두 삭제됩니다.\n계속 진행하시겠습니까?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('취소'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('확인'),
                          ),
                        ],
                      ),
                );

                if (confirm != true) return; // 취소했으면 종료

                final userId = FirebaseAuth.instance.currentUser?.uid;
                print('🔍 User ID: $userId');

                if (userId != null) {
                  final firestore = FirebaseFirestore.instance;
                  final userRef = firestore.collection('users').doc(userId);
                  final subcollections = ['register_cards', 'defaultGoal'];

                  try {
                    for (final subcollection in subcollections) {
                      print('📂 Deleting subcollection: $subcollection');
                      final snapshots =
                          await userRef.collection(subcollection).get();
                      for (final doc in snapshots.docs) {
                        print('🗑️ Deleting doc ${doc.id} in $subcollection');
                        await doc.reference.delete();
                      }
                    }

                    // Delete all fields in the user document except userId
                    final userDoc = await userRef.get();
                    if (userDoc.exists) {
                      final fields = userDoc.data()!.keys.toList();
                      for (final field in fields) {
                        print('❌ Deleting field: $field');
                        await userRef.update({field: FieldValue.delete()});
                      }
                    }

                    print('✅ All user fields and subcollections deleted');

                    Provider.of<AppState>(
                      context,
                      listen: false,
                    ).reloadAllData(context);

                    if (context.mounted) {
                      setState(() {}); // UI 갱신
                      await showDialog(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  12,
                                ), // 라운드 값 조정
                              ),
                              title: const Text('초기화 완료'),
                              content: const Text(
                                '이번 달 데이터가 성공적으로 \n초기화되었습니다.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('확인'),
                                ),
                              ],
                            ),
                      );
                    }
                  } catch (e) {
                    print('❌ Error deleting data: $e');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('데이터 삭제 실패: ${e.toString()}')),
                      );
                    }
                  }
                } else {
                  print('⚠️ User ID is null');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade400,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: const Text('이번 달 데이터 초기화'),
            ),
            const SizedBox(height: 12),
            const Text(
              '이 버튼을 누르면 이번 달의 모든 소비 기록 및 카테고리 데이터를 삭제합니다. '
              '복구할 수 없으니 주의해주세요.',
              style: TextStyle(color: Colors.redAccent),
            ),
            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil('/login', (route) => false);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[400],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('로그아웃'),
              ),
            ),
            const SizedBox(height: 100),
            const Text('앱 버전: 1.0.0'),
            const Text('개발자: Woohyun Kim'),
          ],
        ),
      ),
    );
  }
}

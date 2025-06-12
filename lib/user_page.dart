import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserPage extends StatelessWidget {
  const UserPage({super.key});

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
            const SizedBox(height: 12),
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
                    borderRadius: BorderRadius.circular(6),
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

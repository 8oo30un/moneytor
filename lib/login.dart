import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      backgroundColor: Color.fromRGBO(247, 247, 249, 1),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/icon/loginIcon.png', // replace with your actual image path
                  width: 300,
                  height: 300,
                ),

                const Text(
                  '당신의 돈을 스마트하고, 모니터링 하는 앱',
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 82),
                ElevatedButton.icon(
                  onPressed: () {},

                  label: const Text('로그인'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 80,
                      vertical: 1,
                    ),
                    textStyle: const TextStyle(fontSize: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10), // 라운드 반경 조절
                    ),
                    shadowColor: Colors.grey.withOpacity(0.1), // 그림자 색상 조절
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {},

                  label: const Text('회원가입'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF91D8F7),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 73,
                      vertical: 1,
                    ),
                    textStyle: const TextStyle(fontSize: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10), // 라운드 반경 조절
                    ),
                    shadowColor: Colors.grey.withOpacity(0.1), // 그림자 색상 조절
                  ),
                ),
                const SizedBox(height: 160),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

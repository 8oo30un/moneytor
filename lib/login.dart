import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void goToSignup() {
    _pageController.animateToPage(
      1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void goToLogin() {
    _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(247, 247, 249, 1),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 102),

                Image.asset(
                  'assets/icon/loginIcon.png',
                  width: 300,
                  height: 300,
                ),
                const Text(
                  '당신의 돈을 스마트하고, 모니터링 하는 앱',
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 102),
                SizedBox(
                  height: 240,
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _LoginButtons(onSignupPressed: goToSignup),
                      _SignupButtons(onBackPressed: goToLogin),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginButtons extends StatelessWidget {
  final VoidCallback onSignupPressed;

  const _LoginButtons({required this.onSignupPressed});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton.icon(
          onPressed: () {},
          label: const Text('로그인'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 1),
            textStyle: const TextStyle(fontSize: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            shadowColor: Colors.grey.withOpacity(0.1),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: onSignupPressed,
          label: const Text('회원가입'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF91D8F7),
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 73, vertical: 1),
            textStyle: const TextStyle(fontSize: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            shadowColor: Colors.grey.withOpacity(0.1),
          ),
        ),
        const SizedBox(height: 120),
      ],
    );
  }
}

class _SignupButtons extends StatelessWidget {
  final VoidCallback onBackPressed;

  const _SignupButtons({required this.onBackPressed});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton.icon(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) {
                final _formKey = GlobalKey<FormState>();
                final TextEditingController idController =
                    TextEditingController();
                final TextEditingController passwordController =
                    TextEditingController();
                final TextEditingController confirmController =
                    TextEditingController();

                return AlertDialog(
                  title: const Text('회원가입'),
                  content: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            controller: idController,
                            decoration: const InputDecoration(labelText: '아이디'),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '아이디를 입력해주세요';
                              }
                              return null;
                            },
                          ),
                          TextFormField(
                            controller: passwordController,
                            decoration: const InputDecoration(
                              labelText: '비밀번호',
                            ),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '비밀번호를 입력해주세요';
                              }
                              final hasSpecial = RegExp(
                                r'[!@#$%^&*(),.?":{}|<>]',
                              ).hasMatch(value);
                              if (!hasSpecial) {
                                return '특수문자를 포함해야 합니다';
                              }
                              return null;
                            },
                          ),
                          TextFormField(
                            controller: confirmController,
                            decoration: const InputDecoration(
                              labelText: '비밀번호 확인',
                            ),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '비밀번호 확인을 입력해주세요';
                              }
                              if (value != passwordController.text) {
                                return '비밀번호가 일치하지 않습니다';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('회원가입 완료')),
                          );
                        }
                      },
                      child: const Text('제출'),
                    ),
                  ],
                );
              },
            );
          },
          label: const Text('회원아이디로 가입'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFAEE9DB),
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 1),
            textStyle: const TextStyle(fontSize: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            shadowColor: Colors.grey.withOpacity(0.1),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () {
            // TODO: Add Google signup logic
          },
          label: const Text('구글 로그인'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4BA9DF),
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 70, vertical: 1),
            textStyle: const TextStyle(fontSize: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            shadowColor: Colors.grey.withOpacity(0.1),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: onBackPressed,
          label: const Text('돌아가기'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 1),
            textStyle: const TextStyle(fontSize: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            shadowColor: Colors.grey.withOpacity(0.1),
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

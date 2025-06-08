import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'home.dart';

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

  void _showLoginFields() {
    _pageController.animateToPage(
      1,
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
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 102),
                SizedBox(
                  height: 240,
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _LoginButtons(
                        onSignupPressed: () {
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
                                          decoration: const InputDecoration(
                                            labelText: '아이디',
                                          ),
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return '아이디를 입력해주세요';
                                            }
                                            final emailRegex = RegExp(
                                              r'^[^@]+@[^@]+\.[^@]+',
                                            );
                                            if (!emailRegex.hasMatch(value)) {
                                              return '올바른 이메일 형식을 입력해주세요';
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
                                            if (value == null ||
                                                value.isEmpty) {
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
                                            if (value == null ||
                                                value.isEmpty) {
                                              return '비밀번호 확인을 입력해주세요';
                                            }
                                            if (value !=
                                                passwordController.text) {
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
                                        FirebaseAuth.instance
                                            .createUserWithEmailAndPassword(
                                              email: idController.text.trim(),
                                              password:
                                                  passwordController.text
                                                      .trim(),
                                            )
                                            .then((
                                              UserCredential userCredential,
                                            ) {
                                              Navigator.pop(context);
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text('회원가입 완료'),
                                                  ),
                                                );
                                              }
                                              debugPrint(
                                                '✅ Firebase user created: ${userCredential.user?.uid}',
                                              );
                                            })
                                            .catchError((e) {
                                              Navigator.pop(context);
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      '회원가입 실패: $e',
                                                    ),
                                                  ),
                                                );
                                              }
                                            });
                                      }
                                    },
                                    child: const Text('제출'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        onLoginPressed: _showLoginFields,
                      ),
                      _LoginFields(onBackPressed: goToLogin),
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
  final VoidCallback onLoginPressed;

  const _LoginButtons({
    required this.onSignupPressed,
    required this.onLoginPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(
          onPressed: onLoginPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 43, vertical: 1),
            textStyle: const TextStyle(fontSize: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            shadowColor: Colors.grey.withOpacity(0.1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/userIcon.png', width: 28, height: 28),
              const SizedBox(width: 15),
              const Text('회원 로그인', style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
        const SizedBox(height: 20),

        ElevatedButton(
          onPressed: () async {
            try {
              final GoogleSignInAccount? googleUser =
                  await GoogleSignIn().signIn();
              if (googleUser == null) return;

              final GoogleSignInAuthentication googleAuth =
                  await googleUser.authentication;
              final credential = GoogleAuthProvider.credential(
                accessToken: googleAuth.accessToken,
                idToken: googleAuth.idToken,
              );

              await FirebaseAuth.instance.signInWithCredential(credential);
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const HomePage()),
                );
              }
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('구글 로그인 성공')));
            } catch (e) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('구글 로그인 실패: $e')));
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 1),
            textStyle: const TextStyle(fontSize: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            shadowColor: Colors.grey.withOpacity(0.1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/googleIcon.png', width: 18, height: 18),
              const SizedBox(width: 11),
              const Text('  구글 로그인', style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: onSignupPressed,
          label: const Text('회원가입', style: TextStyle(fontSize: 14)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF91D8F7),
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 78, vertical: 1),
            textStyle: const TextStyle(fontSize: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            shadowColor: Colors.grey.withOpacity(0.1),
          ),
        ),
        const SizedBox(height: 56),
      ],
    );
  }
}

class _LoginFields extends StatefulWidget {
  final VoidCallback onBackPressed;

  const _LoginFields({required this.onBackPressed});

  @override
  State<_LoginFields> createState() => _LoginFieldsState();
}

class _LoginFieldsState extends State<_LoginFields> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController idController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void dispose() {
    idController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _login() {
    String? errorMessage;
    if (idController.text.isEmpty) {
      errorMessage = '아이디를 입력해주세요';
    } else if (passwordController.text.isEmpty) {
      errorMessage = '비밀번호를 입력해주세요';
    }

    if (errorMessage != null) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('로그인 실패'),
              content: Text(errorMessage!),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('확인'),
                ),
              ],
            ),
      );
    } else {
      FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: idController.text.trim(),
            password: passwordController.text.trim(),
          )
          .then((userCredential) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('로그인 성공')));
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          })
          .catchError((e) {
            showDialog(
              context: context,
              builder:
                  (context) => AlertDialog(
                    title: const Text('로그인 실패'),
                    content: Text('오류: $e'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('확인'),
                      ),
                    ],
                  ),
            );
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: idController,
            decoration: const InputDecoration(labelText: '아이디'),
          ),
          TextFormField(
            controller: passwordController,
            decoration: const InputDecoration(labelText: '비밀번호'),
            obscureText: true,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _login,
            child: const Text('로그인'),
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
          const SizedBox(height: 12),
          TextButton(
            onPressed: widget.onBackPressed,
            child: const Text('뒤로가기'),
          ),
        ],
      ),
    );
  }
}

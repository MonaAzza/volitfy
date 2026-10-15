import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_colors.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../widgets/social_button.dart';
import '../home/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _rememberMe = false;
  bool _isPasswordVisible = false;

  String? _emailError;
  String? _passwordError;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool('remember_me') ?? false;

    if (rememberMe && mounted) {
      setState(() {
        _rememberMe = true;
        _emailController.text = prefs.getString('saved_email') ?? '';
        _passwordController.text = prefs.getString('saved_password') ?? '';
      });
    }
  }

  Future<void> _handleLogin() async {
    setState(() {
      _emailError = _emailController.text.trim().isEmpty ? 'الرجاء إدخال البريد الإلكتروني' : null;
      _passwordError = _passwordController.text.trim().isEmpty ? 'الرجاء إدخال كلمة المرور' : null;
    });

    if (_emailError != null || _passwordError != null) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    if (_rememberMe) {
      await prefs.setBool('remember_me', true);
      await prefs.setString('saved_email', _emailController.text.trim());
      await prefs.setString('saved_password', _passwordController.text.trim());
    } else {
      await prefs.remove('remember_me');
      await prefs.remove('saved_email');
      await prefs.remove('saved_password');
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم تسجيل الدخول بنجاح!'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => HomeScreen(userEmail: _emailController.text.trim())),
    );
  }

  void _handleSocialLogin(String providerName) {
    String socialEmail = '${providerName.toLowerCase()}@user.com';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم تسجيل الدخول بنجاح عبر $providerName!'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => HomeScreen(userEmail: socialEmail)),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 25.w, vertical: 20.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 30.h),

              Text(
                'تسجيل الدخول',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),

              SizedBox(height: 94.h),

              CustomTextField(
                controller: _emailController,
                hintText: 'البريد الإلكتروني',
                prefixIcon: Icons.mail_outline_rounded,
                errorText: _emailError,
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) => setState(() {}),
              ),

              SizedBox(height: 20.h),


              CustomTextField(
                controller: _passwordController,
                hintText: 'كلمة المرور',
                prefixIcon: Icons.lock_outline_rounded,
                errorText: _passwordError,
                obscureText: !_isPasswordVisible,
                onChanged: (_) => setState(() {}),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: AppColors.textSecondary,
                    size: 20.r,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ),

              SizedBox(height: 20.h),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 20.r,
                        height: 20.r,
                        child: Checkbox(
                          value: _rememberMe,
                          onChanged: (val) {
                            setState(() {
                              _rememberMe = val ?? false;
                            });
                          },
                          activeColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'تذكرني',
                        style: TextStyle(fontSize: 13.sp, color: AppColors.textDark),
                      ),
                    ],
                  ),

                  GestureDetector(
                    onTap: () {},
                    child: Text(
                      'نسيت كلمة المرور؟',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 94.h),


              Center(
                child: CustomButton(
                  text: 'تسجيل الدخول',
                  onPressed: _handleLogin,
                ),
              ),

              SizedBox(height: 24.h),


              Row(
                children: [
                  const Expanded(child: Divider(color: AppColors.inputBorder)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Text(
                      'أو',
                      style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
                    ),
                  ),
                  const Expanded(child: Divider(color: AppColors.inputBorder)),
                ],
              ),

              SizedBox(height: 24.h),

              SocialButton(
                text: 'المتابعة باستخدام Google',
                iconWidget: Image.asset(
                  'images/google.png',
                  width: 22.r,
                  height: 22.r,
                  fit: BoxFit.contain,
                ),
                onPressed: () => _handleSocialLogin('Google'),
              ),

              SizedBox(height: 12.h),

              SocialButton(
                text: 'المتابعة باستخدام Twitter',
                iconWidget: Image.asset(
                  'images/twitter.png',
                  width: 22.r,
                  height: 22.r,
                  fit: BoxFit.contain,
                ),
                onPressed: () => _handleSocialLogin('Twitter'),
              ),

              SizedBox(height: 46.h),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'ليس لديك حساب؟ ',
                    style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: Text(
                      'إنشاء حساب',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }
}
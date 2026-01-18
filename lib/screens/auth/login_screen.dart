import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:mileage_calculator/controllers/mileage_controller.dart';
import 'package:mileage_calculator/screens/auth/email_verification_screen.dart';
import 'package:mileage_calculator/screens/auth/registration_screen.dart';
import 'package:mileage_calculator/services/auth_service.dart';
import 'package:mileage_calculator/widgets/main_navigation.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late final AuthService _authService;

  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    try {
      _authService = Get.find<AuthService>();
    } catch (e) {
      _authService = Get.put(AuthService());
    }
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),

                  // Illustration
                  Center(
                    child: Container(
                      height: MediaQuery.of(context).size.height * 0.22,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SvgPicture.asset(
                        'assets/svgs/sign-in SVG.svg',
                        fit: BoxFit.contain,
                        placeholderBuilder:
                            (context) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Welcome Back Title
                  const Text(
                    'Welcome Back!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F1F1F),
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 6),

                  // Subtitle
                  Text(
                    'Please sign in to continue tracking your fuel efficiency.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 20),

                  // Email Label
                  const Text(
                    'Email',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F1F1F),
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Email TextField
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!GetUtils.isEmail(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      hintText: 'someone@example.com',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 15,
                      ),
                      suffixIcon: const Icon(
                        Icons.email_outlined,
                        color: Color(0xFF2563EB),
                        size: 22,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8F9FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color(0xFFE0E0E0),
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color(0xFFE0E0E0),
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color(0xFF2563EB),
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Colors.red,
                          width: 1,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Colors.red,
                          width: 1,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      errorStyle: const TextStyle(height: 0.8, fontSize: 12),
                      errorMaxLines: 1,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Password Label
                  const Text(
                    'Password',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F1F1F),
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Password TextField
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      hintText: 'password',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 15,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: const Color(0xFF2563EB),
                          size: 22,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8F9FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color(0xFFE0E0E0),
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color(0xFFE0E0E0),
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color(0xFF2563EB),
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Colors.red,
                          width: 1,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Colors.red,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      errorStyle: const TextStyle(height: 0.8, fontSize: 12),
                      errorMaxLines: 1,
                    ),
                  ),

                  // Forgot Password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed:
                          () => Get.to(() => const EmailVerificationScreen()),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 0,
                          vertical: 4,
                        ),
                      ),
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F1F1F),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Sign In Button with gradient and shadow
                  Obx(
                    () => SizedBox(
                      height: 56,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1E5EFF), Color(0xFF3B82F6)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2563EB).withOpacity(0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                              spreadRadius: 0,
                            ),
                            BoxShadow(
                              color: const Color(0xFF2563EB).withOpacity(0.2),
                              blurRadius: 32,
                              offset: const Offset(0, 12),
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed:
                              _authService.isLoading.value ? null : _signIn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shadowColor: Colors.transparent,
                            disabledBackgroundColor: Colors.transparent,
                            disabledForegroundColor: Colors.white,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          child:
                              _authService.isLoading.value
                                  ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                  : const Text(
                                    'Sign In',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Divider
                  Row(
                    children: [
                      const Expanded(
                        child: Divider(color: Color(0xFFE5E7EB), thickness: 1),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'or',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Expanded(
                        child: Divider(color: Color(0xFFE5E7EB), thickness: 1),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Google Sign In Button
                  Obx(
                    () => SizedBox(
                      height: 56,
                      child: OutlinedButton(
                        onPressed:
                            _authService.isLoading.value
                                ? null
                                : _signInWithGoogle,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: const BorderSide(
                            color: Color(0xFF2563EB),
                            width: 1.8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              'assets/icons/google-icon.svg',
                              height: 24,
                              width: 24,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Continue with Google',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F1F1F),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Continue Without Account
                  Center(
                    child: TextButton(
                      onPressed: _continueWithoutAccount,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      child: const Text(
                        'Continue Without Account',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Sign Up Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Don\'t have an account? ',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Get.to(() => const RegistrationScreen()),
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _signIn() async {
    if (_formKey.currentState!.validate()) {
      final result = await _authService.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (result) {
        // Wait a bit for the auth state to propagate and sync to complete
        await Future.delayed(const Duration(milliseconds: 1000));

        // Ensure all controllers are refreshed after successful login
        await _refreshControllersAfterLogin();

        Get.offAll(() => const MainNavigation());
      }
    }
  }

  Future<void> _refreshControllersAfterLogin() async {
    try {
      // Wait to ensure MainNavigation has initialized the controller
      await Future.delayed(const Duration(milliseconds: 500));

      // Get MileageController and force refresh
      MileageGetxController mileageController;

      // Try to find existing controller first
      try {
        mileageController = Get.find<MileageGetxController>();
      } catch (e) {
        // If not found, create it - MainNavigation will also create one
        print('⚠️ MileageController not found, creating new instance');
        mileageController = Get.put(MileageGetxController());
      }

      await mileageController.refreshFromFuelingService();

      print('🔄 Controllers refreshed after login');
    } catch (e) {
      print('❌ Error refreshing controllers: $e');
      // Don't prevent navigation even if refresh fails
    }
  }

  Future<void> _signInWithGoogle() async {
    final result = await _authService.signInWithGoogle();
    if (result == 'Success') {
      // Wait a bit for the auth state to propagate and sync to complete
      await Future.delayed(const Duration(milliseconds: 1000));

      // Ensure all controllers are refreshed after successful login
      await _refreshControllersAfterLogin();

      Get.offAll(() => const MainNavigation());
    }
  }

  Future<void> _continueWithoutAccount() async {
    await _authService.enableGuestMode();

    Get.snackbar(
      'Guest Mode',
      'Your data will be stored locally only',
      backgroundColor: Colors.orange,
      colorText: Colors.white,
      borderRadius: 12,
      margin: const EdgeInsets.all(16),
      snackPosition: SnackPosition.TOP,
      icon: const Icon(Icons.info_outline, color: Colors.white),
      duration: const Duration(seconds: 3),
    );

    Get.offAll(() => const MainNavigation());
  }
}

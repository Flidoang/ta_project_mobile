import 'package:book_app/assets/wave_clipper.dart';
import 'package:book_app/pages/user/login_user.dart';
import 'package:book_app/service/database.dart';
import 'package:book_app/service/shared_preference.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SignupUser extends StatefulWidget {
  const SignupUser({super.key});

  @override
  State<SignupUser> createState() => _SignupUserState();
}

class _SignupUserState extends State<SignupUser> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool isLoading = false;

  register() async {
    final String name = _nameController.text.trim();
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();
    // final String confirmPassword = _confirmPasswordController.text.trim();

    // Set state untuk menampilkan loading indicator di UI
    setState(() {
      isLoading = true;
    });

    try {
      // 3. Proses Registrasi ke Firebase
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      String userId = userCredential.user!.uid;

      Map<String, dynamic> userInfoMap = {
        "Name": name,
        "Email": email,
        "Id": userId,
        "role": "user",
      };
      await DatabaseMethod().addUserInfo(userInfoMap, userId);
      await SharedPreferenceHelper().saveUserName(_nameController.text);
      await SharedPreferenceHelper().saveUserEmail(_emailController.text);
      await SharedPreferenceHelper().saveUserId(userId);

      // Navigasi setelah berhasil (PENTING: Cek 'mounted' sebelum navigasi)
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Register Successfully")));
        Navigator.pushReplacement(
          // Gunakan pushReplacement agar tidak bisa kembali ke halaman signup
          context,
          MaterialPageRoute(builder: (context) => LoginUser()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = "An error occurred. Please try again.";
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        message = 'An account already exists for that email.';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is not valid.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
      );
    } catch (e) {
      // Menangkap error umum lainnya
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("An unexpected error occurred: ${e.toString()}"),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      // Set state untuk menyembunyikan loading indicator, baik berhasil maupun gagal
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: SizedBox(
          height: size.height,
          child: Stack(
            children: [
              // Header dengan bentuk kurva
              ClipPath(
                clipper: WaveClipper(),
                child: Container(
                  height: size.height * 0.35, // Dibuat sedikit lebih pendek
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF50E3C2),
                        Color(0xFF4A90E2),
                      ], // Warna dibalik untuk pembeda
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_add, color: Colors.white, size: 70),
                        SizedBox(height: 16),
                        Text(
                          'Buat Akun Baru',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Bagian Form
              Padding(
                padding: EdgeInsets.only(top: size.height * 0.3),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildTextField(
                          hint: 'Nama Lengkap',
                          icon: Icons.person_outline,
                          controller: _nameController,
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          hint: 'Email',
                          icon: Icons.email_outlined,
                          controller: _emailController,
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          hint: 'Password',
                          icon: Icons.lock_outline,
                          isPassword: true,
                          controller: _passwordController,
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          hint: 'Konfirmasi Password',
                          icon: Icons.lock_outline,
                          isConfirmPassword: true,
                          controller: _confirmPasswordController,
                        ),
                        const SizedBox(height: 30),

                        // Tombol Daftar
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4A90E2),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 5,
                            ),
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                register();
                              }
                            },
                            child: isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 3,
                                    ),
                                  )
                                : const Text(
                                    'DAFTAR',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Navigasi kembali ke Login
                        _buildLoginNavigation(),
                      ],
                    ),
                  ),
                ),
              ),

              // Tombol Kembali
              Positioned(
                top: 40,
                left: 10,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper Widget untuk TextFormField
  Widget _buildTextField({
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool isConfirmPassword = false,
    TextEditingController? controller,
  }) {
    return TextFormField(
      controller: controller,
      obscureText:
          (isPassword && !_isPasswordVisible) ||
          (isConfirmPassword && !_isConfirmPasswordVisible),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF4A90E2)),
        suffixIcon: isPassword || isConfirmPassword
            ? IconButton(
                icon: Icon(
                  (isPassword && _isPasswordVisible) ||
                          (isConfirmPassword && _isConfirmPasswordVisible)
                      ? Icons.visibility
                      : Icons.visibility_off,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    if (isPassword) _isPasswordVisible = !_isPasswordVisible;
                    if (isConfirmPassword)
                      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                  });
                },
              )
            : null,
        filled: true,
        fillColor: Colors.grey.shade200,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '$hint tidak boleh kosong';
        }
        if (isConfirmPassword && value != _passwordController.text) {
          return 'Password tidak cocok';
        }
        return null;
      },
    );
  }

  // Helper untuk navigasi ke login
  Widget _buildLoginNavigation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Sudah punya akun?", style: TextStyle(color: Colors.grey)),
        TextButton(
          onPressed: () {
            // Kembali ke halaman sebelumnya (login)
            Navigator.of(context).pop();
          },
          child: const Text(
            'Masuk',
            style: TextStyle(
              color: Color(0xFF4A90E2),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

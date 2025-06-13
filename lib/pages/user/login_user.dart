import 'package:book_app/assets/wave_clipper.dart';
import 'package:book_app/helper/navigation_user.dart';
import 'package:book_app/pages/user/signup_user.dart';
import 'package:book_app/service/database.dart';
import 'package:book_app/service/shared_preference.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginUser extends StatefulWidget {
  const LoginUser({super.key});

  @override
  State<LoginUser> createState() => _LoginUserState();
}

class _LoginUserState extends State<LoginUser> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool isLoading = false;

  login() async {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    setState(() {
      isLoading = true;
    });

    try {
      // 1. Proses Login ke Firebase
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      // 2. Ambil data user dari Firestore menggunakan UID
      //    (Asumsi kamu punya method seperti ini di DatabaseMethod)
      Map<String, dynamic>? userInfoMap = await DatabaseMethod().getUserInfo(
        userCredential.user!.uid,
      );

      if (userInfoMap != null) {
        // 3. Simpan data sesi ke SharedPreferences
        await SharedPreferenceHelper().saveUserName(userInfoMap["Name"]);
        await SharedPreferenceHelper().saveUserEmail(userInfoMap["Email"]);
        await SharedPreferenceHelper().saveUserId(userInfoMap["Id"]);
        // Jika ada data lain seperti URL foto, simpan juga di sini
      }

      // Navigasi setelah berhasil (PENTING: Cek 'mounted' sebelum navigasi)
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Register Successfully")));
        Navigator.pushReplacement(
          // Gunakan pushReplacement agar tidak bisa kembali ke halaman signup
          context,
          MaterialPageRoute(builder: (context) => NavigationUser()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = "An error occurred. Please try again.";
      if (e.code == 'user-not-found') {
        message = 'No user Found for that Email';
      } else if (e.code == 'wrong-password') {
        message = 'Wrong Password';
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
    _emailController.dispose();
    _passwordController.dispose();
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
              // Bagian Header dengan bentuk kurva
              ClipPath(
                clipper: WaveClipper(),
                child: Container(
                  height: size.height * 0.45,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF4A90E2), Color(0xFF50E3C2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person, color: Colors.white, size: 80),
                        SizedBox(height: 16),
                        Text(
                          'Selamat Datang!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Masuk untuk melanjutkan',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Bagian Form
              Padding(
                padding: EdgeInsets.only(top: size.height * 0.4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Input Email
                        _buildTextField(
                          hint: 'Email',
                          icon: Icons.email_outlined,
                          controller: _emailController,
                        ),
                        const SizedBox(height: 20),
                        // Input Password
                        _buildTextField(
                          hint: 'Password',
                          icon: Icons.lock_outline,
                          controller: _passwordController,
                          isPassword: true,
                        ),
                        const SizedBox(height: 40),
                        // Tombol Login
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
                                // Navigasi ke dashboard utama setelah login
                                login();
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
                                    'LOGIN',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // --- NAVIGASI KE SIGNUP DITAMBAHKAN DI SINI ---
                        _buildSignupNavigation(),
                      ],
                    ),
                  ),
                ),
              ),

              // Tombol Kembali (Back Button)
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
    TextEditingController? controller,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? !_isPasswordVisible : false,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: const Color(0xFF4A90E2)),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
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
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 20,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '$hint tidak boleh kosong';
        }
        return null;
      },
    );
  }

  // Widget baru untuk navigasi ke halaman signup
  Widget _buildSignupNavigation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Belum punya akun?", style: TextStyle(color: Colors.grey)),
        TextButton(
          onPressed: () {
            // Navigasi ke halaman signup
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (context) => const SignupUser()));
          },
          child: const Text(
            'Daftar',
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

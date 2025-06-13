// Lokasi: lib/pages/splass_screen.dart (VERSI GABUNGAN)
import 'dart:async';
import 'package:book_app/helper/navigation_admin.dart';
import 'package:book_app/helper/navigation_user.dart';
import 'package:book_app/pages/exception_screen.dart';
import 'package:book_app/pages/role_selection.dart';
import 'package:book_app/pages/user/login_user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class SplassScreen extends StatefulWidget {
  const SplassScreen({super.key});

  @override
  State<SplassScreen> createState() => _SplassScreenState();
}

class _SplassScreenState extends State<SplassScreen> {
  @override
  void initState() {
    super.initState();
    _checkInitialState();
  }

  // --- FUNGSI UTAMA UNTUK MENGECEK SEMUA KONDISI AWAL ---
  Future<void> _checkInitialState() async {
    // Tunda sebentar agar splash screen terlihat
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    // Langkah 1: Periksa koneksi internet
    final connectivityResult = await (Connectivity().checkConnectivity());
    if (!connectivityResult.contains(ConnectivityResult.mobile) &&
        !connectivityResult.contains(ConnectivityResult.wifi)) {
      // Jika tidak ada koneksi, arahkan ke halaman error
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ExceptionScreen(
            onRetry:
                _checkInitialState, // Saat "Coba Lagi", jalankan ulang seluruh pengecekan
          ),
        ),
      );
      return; // Hentikan fungsi di sini
    }

    // Langkah 2: Jika ada koneksi, periksa status login
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // --- KASUS: ADA KONEKSI, TAPI TIDAK ADA YANG LOGIN ---
      // Arahkan ke halaman pemilihan peran atau login
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
      );
    } else {
      // --- KASUS: ADA KONEKSI DAN ADA YANG LOGIN ---
      // Periksa role pengguna di Firestore
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists && doc.data()?['role'] == 'admin') {
          // Role adalah 'admin', arahkan ke dashboard admin
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const NavigationAdmin()),
          );
        } else {
          // Role adalah 'user' atau lainnya, arahkan ke dashboard user
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const NavigationUser()),
          );
        }
      } catch (e) {
        // Jika terjadi error (misal Firestore offline), arahkan ke login sebagai pengaman
        print("Error checking user role: $e");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginUser()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueAccent,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            FlutterLogo(size: 100),
            SizedBox(height: 24),
            Text(
              'Selamat Datang',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 16),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

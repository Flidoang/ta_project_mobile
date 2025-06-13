import 'package:book_app/pages/user/dashboard_page.dart';
import 'package:book_app/pages/user/profile_page.dart';
import 'package:book_app/pages/user/status_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NavigationUser extends StatefulWidget {
  const NavigationUser({super.key});

  @override
  State<NavigationUser> createState() => _NavigationUserState();
}

class _NavigationUserState extends State<NavigationUser> {
  // Variabel untuk menyimpan indeks halaman yang sedang aktif
  int _selectedIndex = 0;

  // Daftar halaman yang akan ditampilkan
  static const List<Widget> _pages = <Widget>[
    DashboardPage(),
    StatusPage(),
    ProfilePage(),
  ];

  // Fungsi yang akan dipanggil saat item navigasi di-tap
  void _onItemTapped(int index) {
    // Tentukan index mana yang dilindungi
    const List<int> protectedIndex = [0, 1, 2];

    // Cek jika index yang dituju adalah halaman yang dilindungi
    if (index == protectedIndex) {
      // Jika ya, periksa status login pengguna
      if (FirebaseAuth.instance.currentUser != null) {
        // Jika sudah login, izinkan akses dengan mengubah state
        setState(() {
          _selectedIndex = index;
        });
      } else {
        // Jika BELUM login, JANGAN ubah state. Tampilkan peringatan.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Anda harus login untuk mengakses halaman ini.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } else {
      // Jika halaman tidak dilindungi (Dashboard atau Pengaturan),
      // langsung izinkan akses.
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Body akan menampilkan halaman dari _pages sesuai dengan _selectedIndex
      body: _pages[_selectedIndex],

      // ---- BAGIAN YANG DIPERBAIKI ----
      bottomNavigationBar: BottomNavigationBar(
        // Ini nama widget yang benar
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Status'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
        currentIndex: _selectedIndex, // Indeks yang aktif
        selectedItemColor: const Color(0xFF4A90E2), // Warna item aktif
        unselectedItemColor: Colors.grey, // Warna item tidak aktif
        onTap: _onItemTapped, // Panggil fungsi saat di-tap
        showUnselectedLabels: true,
      ),
    );
  }
}

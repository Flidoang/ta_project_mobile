// Lokasi: lib/helper/navigation_admin.dart (DENGAN PERBAIKAN UI)
import 'package:book_app/pages/admin/addbike_page.dart';
import 'package:book_app/pages/admin/dashboard_admin_page.dart';
import 'package:book_app/pages/admin/monitoring_page.dart';
import 'package:book_app/pages/admin/setting_admin_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NavigationAdmin extends StatefulWidget {
  const NavigationAdmin({super.key});

  @override
  State<NavigationAdmin> createState() => _NavigationAdminState();
}

class _NavigationAdminState extends State<NavigationAdmin> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = <Widget>[
    DashboardAdminPage(),
    AddbikePage(),
    MonitoringPage(), // Halaman monitoring
    SettingAdminPage(), // Halaman setting
  ];

  void _onItemTapped(int index) {
    if (FirebaseAuth.instance.currentUser != null) {
      setState(() {
        _selectedIndex = index;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda harus login untuk mengakses halaman admin.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        // --- PERBAIKAN UTAMA ADA DI DUA BARIS INI ---
        type: BottomNavigationBarType
            .fixed, // Mencegah item bergeser & menghilangkan label
        unselectedItemColor:
            Colors.grey.shade600, // Memberi warna pada item yang tidak aktif
        // ---------------------------------------------
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box_outlined),
            label: 'Item',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.monitor_heart_outlined,
            ), // Mengganti ikon agar sesuai
            label: 'Monitoring',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_rounded), // Mengganti ikon agar sesuai
            label: 'Setting',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepOrange,
        onTap: _onItemTapped,
      ),
    );
  }
}

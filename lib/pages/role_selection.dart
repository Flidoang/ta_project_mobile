// ignore_for_file: deprecated_member_use

import 'package:book_app/pages/admin/login_admin.dart';
import 'package:book_app/pages/user/login_user.dart';
import 'package:flutter/material.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  // Helper widget untuk membuat kartu peran agar tidak mengulang kode
  Widget _buildRoleCard({
    required BuildContext context,
    required String roleName,
    required IconData icon,
    required Color startColor,
    required Color endColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Container(
        // Dekorasi untuk bayangan yang lebih artistik
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: startColor.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          borderRadius: BorderRadius.circular(20),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              // Efek highlight saat disentuh
              splashColor: Colors.white.withOpacity(0.2),
              highlightColor: Colors.white.withOpacity(0.1),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [startColor, endColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 70, color: Colors.white),
                      const SizedBox(height: 16),
                      Text(
                        roleName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Latar belakang dengan gradasi halus
      backgroundColor: const Color(0xFFF0F4F8),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Judul Halaman
              const Text(
                'Pilih Peran Anda',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E2A38),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Masuk sebagai user atau administrator',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 50),

              // Baris yang berisi dua kartu peran
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Kartu untuk User
                  _buildRoleCard(
                    context: context,
                    roleName: 'User',
                    icon: Icons.person,
                    startColor: const Color(0xFF4A90E2),
                    endColor: const Color(0xFF50E3C2),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const LoginUser(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 20),
                  // Kartu untuk Admin
                  _buildRoleCard(
                    context: context,
                    roleName: 'Admin',
                    icon: Icons.admin_panel_settings,
                    startColor: const Color(0xFFF5A623),
                    endColor: const Color(0xFFD0021B),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const LoginAdmin(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

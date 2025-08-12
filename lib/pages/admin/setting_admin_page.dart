// Lokasi: lib/pages/admin/setting_admin_page.dart (BARU)
import 'package:book_app/pages/role_selection.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SettingAdminPage extends StatefulWidget {
  const SettingAdminPage({super.key});

  @override
  State<SettingAdminPage> createState() => _SettingAdminPageState();
}

class _SettingAdminPageState extends State<SettingAdminPage> {
  String? _adminName;
  String? _adminEmail;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAdminData();
  }

  // --- FUNGSI UNTUK MENGAMBIL DATA ADMIN ---
  Future<void> _fetchAdminData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists && mounted) {
          setState(() {
            _adminName = doc.data()?['Name'];
            _adminEmail = doc.data()?['Email'];
          });
        }
      } catch (e) {
        print("Error loading admin data: $e");
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  // --- FUNGSI UNTUK LOGOUT DENGAN KONFIRMASI ---
  Future<void> _logout() async {
    final bool? confirmLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Anda akan keluar dari sesi admin.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmLogout == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5), // Latar belakang abu-abu cerah
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text(
          'Pengaturan Admin',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildProfileHeader(),
                const SizedBox(height: 24),
                _buildSettingsSection(
                  title: 'Manajemen Akun',
                  children: [
                    _buildSettingsTile(
                      icon: Icons.lock_outline,
                      title: 'Ubah Password',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Halaman ubah password belum tersedia.',
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSettingsSection(
                  title: 'Manajemen Aplikasi',
                  children: [
                    _buildSettingsTile(
                      icon: Icons.people_outline,
                      title: 'Manajemen Pengguna',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Halaman manajemen pengguna belum tersedia.',
                            ),
                          ),
                        );
                      },
                    ),
                    _buildSettingsTile(
                      icon: Icons.notifications_none,
                      title: 'Notifikasi',
                      onTap: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                _buildLogoutButton(),
              ],
            ),
    );
  }

  // --- WIDGET BUILDER HELPER ---

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 35,
            backgroundColor: Colors.deepOrange,
            child: Icon(Icons.shield_outlined, color: Colors.white, size: 35),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _adminName ?? 'Nama Admin',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _adminEmail ?? 'email.admin@domain.com',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.bold,
            fontSize: 12,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey.shade800),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }

  Widget _buildLogoutButton() {
    return ElevatedButton.icon(
      icon: const Icon(Icons.logout),
      label: const Text('Logout'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red.shade400,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 2,
        shadowColor: Colors.red.shade200,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      onPressed: _logout,
    );
  }
}

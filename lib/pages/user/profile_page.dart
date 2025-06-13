import 'package:book_app/pages/role_selection.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // State untuk menyimpan data user dan status loading
  String? _userName;
  String? _userEmail;
  String? _profileImageUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // --- FUNGSI UNTUK MENGAMBIL DATA PENGGUNA DARI FIRESTORE ---
  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists && mounted) {
          setState(() {
            _userName = doc.data()?['Name'];
            _userEmail = doc.data()?['Email'];
            // Asumsi ada field 'imageUrl' di dokumen user
            _profileImageUrl = doc.data()?['imageUrl'];
          });
        }
      } catch (e) {
        print("Error loading user data: $e");
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  // --- FUNGSI UNTUK LOGOUT ---
  Future<void> _logout() async {
    // Tampilkan dialog konfirmasi
    final bool? confirmLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar dari akun Anda?'),
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

    // Jika pengguna menekan "Logout"
    if (confirmLogout == true) {
      await FirebaseAuth.instance.signOut();
      // Arahkan ke halaman login dan hapus semua halaman sebelumnya
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
          (route) => false,
        );
      }
    }
  }

  // --- FUNGSI UNTUK EDIT PROFIL ---
  void navigateToEditProfile() {
    // Nanti kita akan buat halaman EditProfilePage
    print('Navigasi ke halaman edit profil...');
    print('Data yang dikirim: Nama: $_userName, Email: $_userEmail');
    // Navigator.push(context, MaterialPageRoute(
    //   builder: (context) => EditProfilePage(
    //     currentName: _userName ?? '',
    //     currentEmail: _userEmail ?? '',
    //     currentImageUrl: _profileImageUrl,
    //   ),
    // ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
          'Profil Saya',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20.0),
              children: [
                Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: _profileImageUrl != null
                          ? NetworkImage(_profileImageUrl!)
                          : const NetworkImage('https://i.pravatar.cc/150'),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _userName ?? 'Nama Pengguna',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _userEmail ?? 'email@pengguna.com',
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                const Divider(),

                // Menu Opsi
                _buildProfileMenu(
                  context,
                  'Edit Profil',
                  Icons.person_outline,
                  Colors.blue,
                  onTap: navigateToEditProfile, // Fungsi edit
                ),
                _buildProfileMenu(
                  context,
                  'Pengaturan',
                  Icons.settings_outlined,
                  Colors.green,
                  onTap: () {},
                ),
                _buildProfileMenu(
                  context,
                  'Bantuan & FAQ',
                  Icons.help_outline,
                  Colors.orange,
                  onTap: () {},
                ),
                const Divider(),
                _buildProfileMenu(
                  context,
                  'Logout',
                  Icons.logout,
                  Colors.red,
                  isLogout: true,
                  onTap: _logout, // Fungsi logout
                ),
              ],
            ),
    );
  }

  // Helper untuk membuat item menu, sekarang dengan parameter onTap
  Widget _buildProfileMenu(
    BuildContext context,
    String title,
    IconData icon,
    Color color, {
    bool isLogout = false,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(
          color: isLogout ? Colors.red : Colors.black,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: isLogout ? null : const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap, // Gunakan fungsi yang dikirimkan
    );
  }
}

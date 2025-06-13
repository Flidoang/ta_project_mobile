import 'package:book_app/pages/user/detail_page.dart';
import 'package:book_app/service/database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String userName = 'Pengguna'; // Nilai default

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // Fungsi untuk mengambil nama pengguna saat halaman dibuka
  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Menggunakan method yang sudah ada di DatabaseMethod
      final userInfo = await DatabaseMethod().getUserInfo(user.uid);
      if (userInfo != null && mounted) {
        setState(() {
          userName = userInfo['Name'] ?? 'Pengguna';
        });
      }
    }
  }

  // Helper untuk sapaan dinamis berdasarkan waktu
  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Selamat Pagi,';
    } else if (hour < 15) {
      return 'Selamat Siang,';
    } else if (hour < 18) {
      return 'Selamat Sore,';
    }
    return 'Selamat Malam,';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FE),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header Kustom
              _buildHeader(),
              const SizedBox(height: 30),

              _buildFeaturedBikes(),
              const SizedBox(height: 30),

              // 2. Kartu Ringkasan (Summary Cards)
              _buildSummaryCards(),
              const SizedBox(height: 30),

              // 3. Menu Aksi Cepat (Quick Actions)
              _buildQuickActions(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // WIDGET BUILDER UNTUK SETIAP BAGIAN
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                getGreeting(), // Sapaan dinamis
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
              Text(
                userName,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E2A38),
                ),
              ),
            ],
          ),
          const Spacer(),
          const CircleAvatar(
            radius: 30,
            backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=budi'),
          ),
        ],
      ),
    );
  }

  // --- WIDGET BARU YANG KREATIF UNTUK MENAMPILKAN DATA "BIKES" ---
  Widget _buildFeaturedBikes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            'Jelajahi Koleksi Kami',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E2A38),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 220, // Tentukan tinggi untuk area scroll horizontal
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('Bikes').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('Koleksi belum tersedia.'));
              }

              var bikeDocs = snapshot.data!.docs;
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 20.0),
                itemCount: bikeDocs.length,
                itemBuilder: (context, index) {
                  var data = bikeDocs[index].data() as Map<String, dynamic>;
                  var docId = bikeDocs[index].id;
                  // Bangun kartu dengan data yang didapat
                  return _buildBikeCard(
                    docId: docId,
                    imageUrl:
                        data['imageUrl'] ??
                        'https://placehold.co/400x600/CCCCCC/FFFFFF?text=No+Image',
                    name: data['name'] ?? 'Tanpa Nama',
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
  // -------------------------------------------------------------------

  Widget _buildSummaryCards() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(left: 20.0),
      child: Row(
        children: [
          _buildSummaryCard(
            '15',
            'Tugas Selesai',
            Icons.check_circle,
            Colors.green,
          ),
          const SizedBox(width: 16),
          _buildSummaryCard('2', 'Proyek Aktif', Icons.work, Colors.blue),
          const SizedBox(width: 16),
          _buildSummaryCard('8', 'Pesan Baru', Icons.message, Colors.orange),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Akses Cepat',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E2A38),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildQuickActionItem(Icons.add_box, 'Tambah Data', Colors.blue),
              _buildQuickActionItem(
                Icons.qr_code_scanner,
                'Scan QR',
                Colors.green,
              ),
              _buildQuickActionItem(Icons.bar_chart, 'Laporan', Colors.orange),
              _buildQuickActionItem(Icons.support_agent, 'Bantuan', Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  // Helper baru untuk kartu koleksi yang estetik
  Widget _buildBikeCard({
    required String docId,
    required String imageUrl,
    required String name,
  }) {
    return GestureDetector(
      onTap: () {
        // AKTIFKAN NAVIGASI INI
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DetailPage(docId: docId)),
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 16.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Gambar sebagai background
              Positioned.fill(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      Container(color: Colors.grey.shade300),
                ),
              ),
              // Gradient overlay untuk teks agar mudah dibaca
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.transparent,
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                ),
              ),
              // Teks informasi
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    const Row(
                      children: [
                        Text(
                          'Lihat Detail',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white70,
                          size: 12,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // WIDGET HELPER KECIL
  Widget _buildSummaryCard(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(label, style: TextStyle(color: color.withOpacity(0.8))),
        ],
      ),
    );
  }

  Widget _buildQuickActionItem(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 30, color: color),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget buildActivityTile(
    IconData icon,
    String title,
    String subtitle,
    Color color,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
    );
  }
}

// Lokasi: lib/screens/admin_dashboard_page.dart (MANAJEMEN BOOKING)
import 'package:book_app/pages/admin/addbike_page.dart'; // Asumsi halaman ini ada
import 'package:book_app/pages/admin/editbike_page.dart';
import 'package:book_app/service/database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DashboardAdminPage extends StatefulWidget {
  const DashboardAdminPage({super.key});

  @override
  State<DashboardAdminPage> createState() => _DashboardAdminPageState();
}

class _DashboardAdminPageState extends State<DashboardAdminPage> {
  String adminName = 'Admin';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAdminData();
  }

  Future<void> _fetchAdminData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists && mounted) {
          setState(() {
            adminName = doc.data()?['Name'] ?? 'Admin';
          });
        }
      }
    } catch (e) {
      print("Error fetching admin data: $e");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> showDeleteDialog(String docId, String bikeName) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Konfirmasi Hapus'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Apakah Anda yakin ingin menghapus "$bikeName"?'),
                const SizedBox(height: 8),
                const Text('Data yang sudah dihapus tidak dapat dikembalikan.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Hapus'),
              onPressed: () async {
                try {
                  await DatabaseMethod().deleteBike(docId);
                  Navigator.of(context).pop();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('"$bikeName" berhasil dihapus.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  Navigator.of(context).pop();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Gagal menghapus data: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> updateBookingStatus(
    String bookingId,
    String newStatus,
    String bikeName,
  ) async {
    try {
      await DatabaseMethod().updateBookingStatus(bookingId, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Booking untuk "$bikeName" telah diubah menjadi $newStatus.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengubah status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepOrange, // Warna dasar untuk status bar
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddbikePage()),
          );
        },
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
        tooltip: 'Tambah Barang',
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Cukup panggil setState untuk memicu rebuild dan refresh data dari stream
          setState(() {});
        },
        child: CustomScrollView(
          slivers: [
            _buildHeaderSliver(context),
            SliverToBoxAdapter(
              child: Container(
                color: const Color(0xFFF7F8FC),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    _buildBookingRequestsSection(context),
                    const SizedBox(height: 30),
                    _buildBikeListSection(context),
                    const SizedBox(height: 90), // Padding untuk FAB
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- UI BARU: Header dibuat sebagai SliverAppBar ---
  Widget _buildHeaderSliver(BuildContext context) {
    return SliverAppBar(
      backgroundColor: Colors.deepOrange,
      expandedHeight: 120.0,
      pinned: true,
      elevation: 0,
      automaticallyImplyLeading: false, // <-- INI PERUBAHANNYA
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        title: Text(
          'Admin Panel',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        background: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 0, 70),
              child: Text(
                'Selamat Datang kembali, $adminName!',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingRequestsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Tindakan Diperlukan',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.notifications_active, color: Colors.deepOrange),
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('bookings')
                .where('status', isEqualTo: 'pending')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildEmptyState(
                  'Tidak Ada Permintaan Booking',
                  Icons.inbox_outlined,
                );
              }

              var bookingDocs = snapshot.data!.docs;
              return ListView.builder(
                itemCount: bookingDocs.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  var bookingData =
                      bookingDocs[index].data() as Map<String, dynamic>;
                  var docId = bookingDocs[index].id;
                  return _buildBookingRequestTile(docId, bookingData);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // --- UI BARU: Section untuk Daftar Barang dengan GridView ---
  Widget _buildBikeListSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Manajemen Barang',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('Bikes')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Terjadi error: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildEmptyState(
                  'Belum Ada Barang',
                  Icons.inventory_2_outlined,
                );
              }

              var bikeDocs = snapshot.data!.docs;
              return GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85, // Rasio untuk kartu grid
                ),
                itemCount: bikeDocs.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  var bikeData = bikeDocs[index].data() as Map<String, dynamic>;
                  var docId = bikeDocs[index].id;
                  return _buildBikeGridItem(docId: docId, data: bikeData);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // --- UI BARU: Desain Kartu Grid untuk Daftar Barang ---
  Widget _buildBikeGridItem({
    required String docId,
    required Map<String, dynamic> data,
  }) {
    final imageUrl =
        data['imageUrl'] ??
        'https://placehold.co/200x200/e0e0e0/ffffff?text=N/A';
    final name = data['name'] ?? 'Tanpa Nama';
    final quantity = data['quantity'] ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Langsung ke halaman edit saat kartu di-tap
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EditbikePage(docId: docId),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      child: Image.network(
                        imageUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey.shade200,
                          child: const Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.white),
                        color: Colors.white,
                        onSelected: (value) {
                          if (value == 'edit') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    EditbikePage(docId: docId),
                              ),
                            );
                          } else if (value == 'delete') {
                            showDeleteDialog(docId, name);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem<String>(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined, size: 20),
                                SizedBox(width: 10),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Hapus',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Stok: $quantity',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
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

  Widget _buildBookingRequestTile(String docId, Map<String, dynamic> data) {
    final bikeName = data['bikeName'] ?? 'N/A';
    final userName = data['userName'] ?? 'N/A';
    final Timestamp startTimestamp = data['startDate'];
    final startDate = DateFormat(
      'dd MMM yyyy, HH:mm',
    ).format(startTimestamp.toDate());

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade100, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            bikeName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            overflow: TextOverflow.ellipsis,
          ),
          const Divider(height: 24),
          _buildRequestInfoRow(Icons.person_outline, 'Pemesan', userName),
          _buildRequestInfoRow(
            Icons.calendar_today_outlined,
            'Waktu',
            startDate,
          ),
          _buildRequestInfoRow(
            Icons.timer_outlined,
            'Durasi',
            '${data['durationInHours']} Jam',
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () =>
                    updateBookingStatus(docId, 'cancelled', bikeName),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Tolak'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () =>
                    updateBookingStatus(docId, 'confirmed', bikeName),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Setujui'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRequestInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade700),
          const SizedBox(width: 12),
          Text('$label:', style: TextStyle(color: Colors.grey.shade700)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

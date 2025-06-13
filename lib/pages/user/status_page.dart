// Lokasi: lib/pages/user/my_bookings_page.dart (DENGAN LOGIKA STATUS OTOMATIS)
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StatusPage extends StatefulWidget {
  const StatusPage({super.key});

  @override
  State<StatusPage> createState() => _StatusPageState();
}

class _StatusPageState extends State<StatusPage> {
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          automaticallyImplyLeading: false,
          title: const Text(
            'Booking Saya',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
          bottom: const TabBar(
            labelColor: Colors.deepOrange,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.deepOrange,
            tabs: [
              Tab(text: 'Pending'),
              Tab(text: 'Aktif'),
              Tab(text: 'Riwayat'),
            ],
          ),
        ),
        body: currentUserId == null
            ? const Center(
                child: Text('Harap login untuk melihat booking Anda.'),
              )
            : TabBarView(
                children: [
                  // Tab 1: Menampilkan booking dengan status 'pending'
                  _buildBookingsList(statuses: ['pending']),

                  // Tab 2: Menampilkan booking 'confirmed' yang MASA BERLAKUNYA MASIH ADA
                  _buildActiveBookingsList(),

                  // Tab 3: Menampilkan semua booking yang sudah lewat
                  _buildHistoryList(),
                ],
              ),
      ),
    );
  }

  // Widget untuk tab 'Pending'
  Widget _buildBookingsList({required List<String> statuses}) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: currentUserId)
          .where('status', whereIn: statuses)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        // ... (logika builder ini tidak berubah)
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Terjadi error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }
        var bookingDocs = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: bookingDocs.length,
          itemBuilder: (context, index) {
            var data = bookingDocs[index].data() as Map<String, dynamic>;
            return _buildBookingCard(data);
          },
        );
      },
    );
  }

  // Widget BARU khusus untuk tab 'Aktif'
  Widget _buildActiveBookingsList() {
    return StreamBuilder<QuerySnapshot>(
      // Query HANYA mengambil booking 'confirmed' yang tanggal selesainya
      // belum terlewat dari waktu sekarang.
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: currentUserId)
          .where('status', isEqualTo: 'confirmed')
          .where('endDate', isGreaterThanOrEqualTo: Timestamp.now())
          .orderBy(
            'endDate',
            descending: false,
          ) // Urutkan dari yang paling cepat selesai
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          // Firebase akan memberikan error jika indeks belum dibuat.
          // Berikan petunjuk kepada user/developer.
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Terjadi error. Kemungkinan besar Anda perlu membuat indeks komposit di Firestore. Cek Debug Console untuk link pembuatan indeks.\n\nError: ${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }
        var bookingDocs = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: bookingDocs.length,
          itemBuilder: (context, index) {
            var data = bookingDocs[index].data() as Map<String, dynamic>;
            return _buildBookingCard(data);
          },
        );
      },
    );
  }

  // Widget BARU khusus untuk tab 'Riwayat'
  Widget _buildHistoryList() {
    // Di tab ini, kita akan menampilkan 2 jenis data:
    // 1. Booking yang statusnya 'cancelled' atau 'completed'.
    // 2. Booking yang statusnya 'confirmed' tapi sudah lewat waktunya.
    // Karena Firestore tidak bisa query OR yang kompleks, kita gunakan 2 StreamBuilder
    // di dalam satu list.

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // StreamBuilder untuk status 'cancelled' dan 'completed'
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('bookings')
                .where('userId', isEqualTo: currentUserId)
                .where('status', whereIn: ['cancelled', 'completed'])
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              return Column(
                children: snapshot.data!.docs.map((doc) {
                  return _buildBookingCard(doc.data() as Map<String, dynamic>);
                }).toList(),
              );
            },
          ),
          // StreamBuilder untuk status 'confirmed' yang sudah lewat
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('bookings')
                .where('userId', isEqualTo: currentUserId)
                .where('status', isEqualTo: 'confirmed')
                .where('endDate', isLessThan: Timestamp.now())
                .orderBy('endDate', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              return Column(
                children: snapshot.data!.docs.map((doc) {
                  return _buildBookingCard(doc.data() as Map<String, dynamic>);
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_rounded, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Tidak ada data booking di sini.',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> data) {
    // ... (UI kartu tidak berubah)
    final bikeName = data['bikeName'] ?? 'N/A';
    final Timestamp startTimestamp = data['startDate'];
    final Timestamp endTimestamp = data['endDate'];
    final status = data['status'] ?? 'N/A';
    final bool isPast = (data['endDate'] as Timestamp).toDate().isBefore(
      DateTime.now(),
    );

    final startDate = DateFormat(
      'dd MMM, HH:mm',
    ).format(startTimestamp.toDate());
    final endDate = DateFormat('dd MMM, HH:mm').format(endTimestamp.toDate());

    Color statusColor;
    String statusText;

    // Logika status baru
    if (status == 'confirmed' && isPast) {
      statusColor = Colors.grey;
      statusText = 'Selesai';
    } else {
      switch (status) {
        case 'confirmed':
          statusColor = Colors.green;
          statusText = 'Dikonfirmasi';
          break;
        case 'cancelled':
          statusColor = Colors.red;
          statusText = 'Dibatalkan';
          break;
        case 'completed':
          statusColor = Colors.blue.shade800;
          statusText = 'Selesai (Manual)';
          break;
        default: // pending
          statusColor = Colors.orange;
          statusText = 'Menunggu Konfirmasi';
      }
    }

    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    bikeName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Chip(
                  label: Text(
                    statusText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: statusColor,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(Icons.calendar_today_outlined, 'Mulai', startDate),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.event_available, 'Selesai', endDate),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.format_list_numbered,
              'Jumlah',
              (data['quantity'] ?? 0).toString(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Text('$label:', style: TextStyle(color: Colors.grey.shade700)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// Lokasi: lib/pages/user/bike_detail_page.dart (BARU)
import 'package:book_app/service/database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DetailPage extends StatefulWidget {
  final String docId; // Menerima ID dokumen dari halaman sebelumnya

  const DetailPage({super.key, required this.docId});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  Map<String, dynamic>? _bikeData;
  bool _isLoading = true;
  bool _isBooking = false;

  @override
  void initState() {
    super.initState();
    _fetchBikeDetails();
  }

  // --- FUNGSI UNTUK MENGAMBIL DETAIL DATA DARI FIRESTORE ---
  Future<void> _fetchBikeDetails() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('Bikes')
          .doc(widget.docId)
          .get();
      if (doc.exists && mounted) {
        setState(() {
          _bikeData = doc.data();
          _isLoading = false;
        });
      } else {
        // Handle jika data tidak ditemukan
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data barang tidak ditemukan.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat detail: $e')));
      }
    }
  }

  // --- FUNGSI BARU UNTUK MENAMPILKAN DIALOG BOOKING ---
  Future<void> showBookingDialog() async {
    DateTime? startDateTime;
    int durationInHours = 1;
    int quantity = 1;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Fungsi untuk memilih tanggal dan waktu
            Future<void> pickStartDateTime() async {
              final pickedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime(2101),
              );

              if (pickedDate == null) return; // Batal memilih tanggal

              final pickedTime = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(DateTime.now()),
              );

              if (pickedTime == null) return; // Batal memilih waktu

              setDialogState(() {
                startDateTime = DateTime(
                  pickedDate.year,
                  pickedDate.month,
                  pickedDate.day,
                  pickedTime.hour,
                  pickedTime.minute,
                );
              });
            }

            return AlertDialog(
              title: const Text('Formulir Booking'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tanggal & Waktu Mulai
                    const Text(
                      'Waktu Mulai',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        startDateTime == null
                            ? 'Pilih Waktu'
                            : DateFormat(
                                'dd MMM yyyy, HH:mm',
                              ).format(startDateTime!),
                      ),
                      onPressed: pickStartDateTime,
                    ),
                    const SizedBox(height: 16),

                    // Durasi Booking
                    const Text(
                      'Durasi Booking (Jam)',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () {
                            if (durationInHours > 1)
                              setDialogState(() => durationInHours--);
                          },
                        ),
                        Text(
                          '$durationInHours',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () {
                            // Batasi durasi jika perlu (misal: maks 24 jam)
                            if (durationInHours < 24) {
                              setDialogState(() => durationInHours++);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Jumlah Barang
                    const Text(
                      'Jumlah Barang',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () {
                            if (quantity > 1) setDialogState(() => quantity--);
                          },
                        ),
                        Text(
                          '$quantity',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () {
                            if (quantity < (_bikeData!['quantity'] ?? 1)) {
                              setDialogState(() => quantity++);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _submitBookingRequest(
                      startDateTime,
                      durationInHours,
                      quantity,
                    );
                    Navigator.pop(context);
                  },
                  child: const Text('Kirim Request'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- FUNGSI PENGIRIMAN REQUEST DENGAN LOGIKA BARU ---
  Future<void> _submitBookingRequest(
    DateTime? start,
    int duration,
    int qty,
  ) async {
    if (start == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap pilih waktu mulai booking.')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda harus login untuk melakukan booking.'),
        ),
      );
      return;
    }

    setState(() => _isBooking = true);

    try {
      String fetchedUserName = 'User Tanpa Nama'; // Nilai default jika gagal
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        fetchedUserName = userDoc.data()?['Name'] ?? 'User Tanpa Nama';
      }
      // Hitung waktu selesai secara otomatis
      final DateTime end = start.add(Duration(hours: duration));

      Map<String, dynamic> bookingData = {
        'bikeId': widget.docId,
        'bikeName': _bikeData!['name'],
        'bikeImageUrl': _bikeData!['imageUrl'],
        'userId': user.uid,
        'userName': fetchedUserName,
        'startDate': Timestamp.fromDate(start),
        'endDate': Timestamp.fromDate(
          end,
        ), // Simpan waktu selesai yang dihitung
        'durationInHours': duration, // Simpan juga durasinya
        'quantity': qty,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      };

      await DatabaseMethod().createBooking(bookingData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Request booking berhasil dikirim! Menunggu konfirmasi admin.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal mengirim request: $e')));
      }
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bikeData == null
          ? const Center(child: Text('Gagal memuat data.'))
          : CustomScrollView(
              slivers: [
                // --- BAGIAN GAMBAR UTAMA (HERO) ---
                SliverAppBar(
                  expandedHeight: 300.0,
                  pinned: true,
                  backgroundColor: Colors.deepOrange,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      _bikeData!['name'] ?? 'Detail Barang',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(blurRadius: 10, color: Colors.black)],
                      ),
                    ),
                    background: Hero(
                      tag: widget.docId, // Tag untuk animasi (opsional)
                      child: Image.network(
                        _bikeData!['imageUrl'] ??
                            'https://placehold.co/600x400',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                ),
                // --- BAGIAN KONTEN DETAIL ---
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Judul dan Stok
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                _bikeData!['name'] ?? 'Tanpa Nama',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Chip(
                              label: Text(
                                'Stok: ${_bikeData!['quantity'] ?? 0}',
                                style: const TextStyle(color: Colors.white),
                              ),
                              backgroundColor: Colors.green.shade600,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Deskripsi
                        const Text(
                          'Deskripsi',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _bikeData!['description'] ?? 'Tidak ada deskripsi.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade700,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 24),

                        // Informasi Tambahan
                        _buildInfoRow(
                          Icons.category_outlined,
                          'Kategori',
                          'Sepeda Listrik',
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          Icons.confirmation_number_outlined,
                          'SKU',
                          'SKU-${widget.docId.substring(0, 6).toUpperCase()}',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      // --- Tombol Aksi di Bawah ---
      bottomNavigationBar: _bikeData == null
          ? null
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.shopping_cart_checkout),
                label: const Text('Booking Sekarang'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: _isBooking ? null : showBookingDialog,
              ),
            ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade500),
        const SizedBox(width: 16),
        Text(
          '$label:',
          style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

import 'dart:io';
import 'package:book_app/service/database.dart';
import 'package:book_app/service/image_upload_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AddbikePage extends StatefulWidget {
  const AddbikePage({super.key});

  @override
  State<AddbikePage> createState() => _AddbikePageState();
}

class _AddbikePageState extends State<AddbikePage> {
  final _formKey = GlobalKey<FormState>();

  // Variabel untuk menyimpan state dari setiap input
  File? _selectedImage;
  final _namaController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _jumlahController = TextEditingController();
  bool _setujuSyarat = false;

  // 1. TAMBAHKAN STATE UNTUK LOADING
  bool isLoading = false;

  @override
  void dispose() {
    // Selalu dispose controller untuk menghindari memory leak
    _namaController.dispose();
    _deskripsiController.dispose();
    _jumlahController.dispose();
    super.dispose();
  }

  // --- FUNGSI BARU UNTUK MEMBERSIHKAN FORM ---
  void _clearForm() {
    setState(() {
      _selectedImage = null;
      _namaController.clear();
      _deskripsiController.clear();
      _jumlahController.clear();
      _setujuSyarat = false;
      // Reset state dari form untuk menghilangkan pesan validasi sebelumnya
      _formKey.currentState?.reset();
    });
  }

  // --- FUNGSI addBikeData() DENGAN PERUBAHAN KE CLOUDINARY ---
  Future<void> addBikeData() async {
    if (!_formKey.currentState!.validate() || _selectedImage == null) {
      // Tampilkan error jika form tidak valid atau gambar kosong
      if (_selectedImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mohon pilih gambar terlebih dahulu.')),
        );
      }
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Anda tidak terautentikasi!')),
      );
      return;
    }
    final String userId = user.uid;

    setState(() {
      isLoading = true;
    });

    try {
      // --- PERUBAHAN UTAMA DI SINI ---
      // Memanggil service upload Cloudinary
      final String? imageUrl = await ImageUploadService.uploadImage(
        _selectedImage!,
      );

      if (imageUrl == null) {
        throw Exception("Gagal mendapatkan URL gambar dari Cloudinary.");
      }
      // -----------------------------

      Map<String, dynamic> bikeData = {
        "name": _namaController.text,
        "description": _deskripsiController.text,
        "quantity": int.tryParse(_jumlahController.text) ?? 0,
        "imageUrl": imageUrl, // <-- URL dari Cloudinary
        "agreedToTerms": _setujuSyarat,
        "createdBy": userId,
        "createdAt": FieldValue.serverTimestamp(),
      };

      await DatabaseMethod().addBike(bikeData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data baru berhasil ditambahkan!'),
            backgroundColor: Colors.green,
          ),
        );
        _clearForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menyimpan data: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text('Formulir Data Baru'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. INPUT GAMBAR
                _buildImagePicker(),
                const SizedBox(height: 24),

                // 2. TEXTFORMFIELD
                _buildTextFormField(
                  controller: _namaController,
                  label: 'Nama Barang',
                  icon: Icons.inventory_2_outlined,
                ),
                const SizedBox(height: 16),
                _buildTextFormField(
                  controller: _deskripsiController,
                  label: 'Deskripsi Singkat',
                  icon: Icons.description_outlined,
                ),
                const SizedBox(height: 16),
                _buildTextFormField(
                  controller: _jumlahController,
                  label: 'Jumlah',
                  icon: Icons.format_list_numbered,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                // 3. CHECKBOX
                _buildCheckbox(),
                const SizedBox(height: 32),

                // 4. TOMBOL SUBMIT
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGET BUILDER HELPER ---

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: () {
        _showImageSourceActionSheet(context);
      },
      child: Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade400,
            style: BorderStyle.solid,
          ),
        ),
        child: _selectedImage != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_selectedImage!, fit: BoxFit.cover),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.camera_alt_outlined,
                    size: 50,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ketuk untuk menambah gambar',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '$label tidak boleh kosong';
        }
        return null;
      },
    );
  }

  Widget _buildCheckbox() {
    return FormField<bool>(
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CheckboxListTile(
              title: const Text('Saya setuju dengan Syarat & Ketentuan'),
              value: _setujuSyarat,
              onChanged: (bool? value) {
                setState(() {
                  _setujuSyarat = value ?? false;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              activeColor: Colors.blueAccent,
            ),
            if (state.errorText != null)
              Padding(
                padding: const EdgeInsets.only(left: 12.0),
                child: Text(
                  state.errorText!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        );
      },
      validator: (value) {
        if (!_setujuSyarat) {
          return 'Anda harus menyetujui syarat & ketentuan';
        }
        return null;
      },
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton.icon(
      icon: const Icon(Icons.send),
      label: isLoading
          ? const CircularProgressIndicator(color: Colors.white)
          : const Text('SIMPAN DATA'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      onPressed: isLoading ? null : addBikeData,
    );
  }

  // --- FUNGSI UNTUK LOGIKA ---

  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Kamera'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeri'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Uncomment seluruh fungsi ini setelah menambahkan image_picker
  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(source: source);

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      // Handle error
      print('Gagal mengambil gambar: $e');
    }
  }
}

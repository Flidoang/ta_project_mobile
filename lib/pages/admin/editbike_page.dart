// Lokasi: pages/admin/editbike_page.dart
import 'dart:io';
import 'package:book_app/service/database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditbikePage extends StatefulWidget {
  final String docId; // Menerima ID dokumen yang akan diedit

  const EditbikePage({super.key, required this.docId});

  @override
  State<EditbikePage> createState() => _EditbikePageState();
}

class _EditbikePageState extends State<EditbikePage> {
  final _formKey = GlobalKey<FormState>();

  // State untuk data yang akan diedit
  File? _selectedImage;
  String? _networkImageUrl; // Untuk menyimpan URL gambar yang sudah ada
  final _namaController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _jumlahController = TextEditingController();
  bool _setujuSyarat = false;

  bool _isLoading = true; // State untuk loading data awal
  bool _isUpdating = false; // State untuk proses update

  @override
  void initState() {
    super.initState();
    _loadBikeData();
  }

  // --- FUNGSI UNTUK MENGAMBIL DATA LAMA ---
  Future<void> _loadBikeData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('Bikes')
          .doc(widget.docId)
          .get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        // Isi semua controller dan state dengan data dari Firestore
        _namaController.text = data['name'] ?? '';
        _deskripsiController.text = data['description'] ?? '';
        _jumlahController.text = (data['quantity'] ?? 0).toString();
        _setujuSyarat = data['agreedToTerms'] ?? false;
        _networkImageUrl = data['imageUrl'];
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memuat data: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _deskripsiController.dispose();
    _jumlahController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Data Barang'),
        backgroundColor: Colors.deepOrange, // Sesuaikan dengan tema admin
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildImagePicker(),
                      const SizedBox(height: 24),
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
                      _buildCheckbox(),
                      const SizedBox(height: 32),
                      _buildSubmitButton(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // --- WIDGET BUILDER HELPER (UI SAMA DENGAN AddBikePage) ---

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
          border: Border.all(color: Colors.grey.shade400),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _selectedImage != null
              ? Image.file(_selectedImage!, fit: BoxFit.cover)
              : (_networkImageUrl != null && _networkImageUrl!.isNotEmpty)
              ? Image.network(
                  _networkImageUrl!,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    return progress == null
                        ? child
                        : const Center(child: CircularProgressIndicator());
                  },
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
                      'Ketuk untuk mengubah gambar',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
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
              activeColor: Colors.deepOrange,
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
      icon: _isUpdating
          ? const SizedBox.shrink()
          : const Icon(Icons.system_update_alt),
      label: _isUpdating
          ? const CircularProgressIndicator(color: Colors.white)
          : const Text('UPDATE DATA'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      onPressed: _isUpdating ? null : _updateData,
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
      print('Gagal mengambil gambar: $e');
    }
  }

  // --- FUNGSI BARU UNTUK PROSES UPDATE ---
  Future<void> _updateData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      // String imageUrl = _networkImageUrl ?? "";
      // Jika user memilih gambar baru, upload gambar tersebut dan dapatkan URL barunya.
      // if (_selectedImage != null) {
      //   // Logika upload gambar ke Firebase Storage di sini...
      //   // imageUrl = await uploadImageAndGetUrl(_selectedImage!);
      // }

      Map<String, dynamic> updatedData = {
        'name': _namaController.text,
        'description': _deskripsiController.text,
        'quantity': int.tryParse(_jumlahController.text) ?? 0,
        'agreedToTerms': _setujuSyarat,
        // 'imageUrl': imageUrl, // gunakan URL baru jika ada
        'updatedAt': FieldValue.serverTimestamp(), // Tandai waktu update
      };

      // Panggil method update dari DatabaseMethod
      await DatabaseMethod().updateBike(widget.docId, updatedData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data berhasil diperbarui!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memperbarui data: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }
}

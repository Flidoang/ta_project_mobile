// Lokasi: lib/pages/user/dashboard_page_revamp.dart
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
  String userName = 'Pengguna';
  String selectedCategory = 'Semua'; // State untuk kategori yang dipilih

  // --- State untuk Carousel ---
  late PageController _promoPageController;
  int _currentPromoPage = 0;
  final List<String> _promoImages = [
    'https://pixel2print.co.uk/images/products/large/139.jpg',
    'https://res.cloudinary.com/dk2yqgmqr/image/upload/v1749902334/cld-sample-4.jpg',
    'https://res.cloudinary.com/dk2yqgmqr/image/upload/v1749902333/samples/coffee.jpg',
  ];
  // -------------------------

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _promoPageController = PageController(viewportFraction: 0.9);
  }

  @override
  void dispose() {
    _promoPageController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userInfo = await DatabaseMethod().getUserInfo(user.uid);
      if (userInfo != null && mounted) {
        setState(() {
          userName = userInfo['Name'] ?? 'Pengguna';
        });
      }
    }
  }

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FE),
      body: CustomScrollView(
        slivers: [
          _buildHeaderSliver(context),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPromoCarouselSection(),
                const SizedBox(height: 30),
                _buildSectionHeaderWithFilter(),
                // const SizedBox(height: 20),
                _buildBikeList(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSliver(BuildContext context) {
    return SliverAppBar(
      backgroundColor: const Color(0xFFF4F7FE),
      expandedHeight: 220.0,
      floating: false,
      pinned: true,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40), // For status bar
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        getGreeting(),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E2A38),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const CircleAvatar(
                    radius: 28,
                    backgroundImage: NetworkImage(
                      'https://i.pravatar.cc/150?u=budi',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildSearchBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Cari sepeda impianmu...',
        hintStyle: TextStyle(color: Colors.grey.shade500),
        prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colors.deepOrange),
        ),
      ),
    );
  }

  // --- WIDGET BARU UNTUK SECTION PROMOSI ---
  Widget _buildPromoCarouselSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            'Promo Spesial',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E2A38),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 150,
          child: PageView.builder(
            controller: _promoPageController,
            itemCount: _promoImages.length,
            onPageChanged: (int page) {
              setState(() {
                _currentPromoPage = page;
              });
            },
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: DecorationImage(
                    image: NetworkImage(_promoImages[index]),
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        // --- INDIKATOR HALAMAN CAROUSEL ---
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_promoImages.length, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              height: 8,
              width: _currentPromoPage == index ? 24 : 8,
              decoration: BoxDecoration(
                color: _currentPromoPage == index
                    ? Colors.deepOrange
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildSectionHeaderWithFilter() {
    final List<String> categories = [
      'Semua',
      'Populer',
      'Listrik',
      'Gunung',
      'Lipat',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pilih Koleksi',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E2A38),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                bool isSelected = selectedCategory == categories[index];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedCategory = categories[index];
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.deepOrange : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? Colors.deepOrange
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      categories[index],
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBikeList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
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

          if (selectedCategory != 'Semua' && selectedCategory != 'Populer') {
            bikeDocs = bikeDocs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return data['category'] == selectedCategory;
            }).toList();
          }

          if (bikeDocs.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 40.0),
              child: Center(
                child: Text('Tidak ada barang di kategori "$selectedCategory"'),
              ),
            );
          }

          return ListView.builder(
            itemCount: bikeDocs.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              var data = bikeDocs[index].data() as Map<String, dynamic>;
              var docId = bikeDocs[index].id;
              return _buildBikeListItem(docId: docId, data: data);
            },
          );
        },
      ),
    );
  }

  Widget _buildBikeListItem({
    required String docId,
    required Map<String, dynamic> data,
  }) {
    final imageUrl =
        data['imageUrl'] ??
        'https://placehold.co/200x200/e0e0e0/ffffff?text=N/A';
    final name = data['name'] ?? 'Tanpa Nama';
    final category = data['category'] ?? 'Uncategorized';
    final price = data['price'] ?? 0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DetailPage(docId: docId)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                imageUrl,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 100,
                  height: 100,
                  color: Colors.grey.shade200,
                  child: const Icon(
                    Icons.image_not_supported,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      const Text(
                        '4.8',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(120 Review)',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }
}

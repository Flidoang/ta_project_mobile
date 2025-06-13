import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseMethod {
  //
  Future addUserInfo(Map<String, dynamic> userInfoMap, String id) async {
    return await FirebaseFirestore.instance
        .collection("users")
        .doc(id)
        .set(userInfoMap);
  }

  // TAMBAHKAN METHOD BARU INI untuk MENGAMBIL data
  Future<Map<String, dynamic>?> getUserInfo(String id) async {
    try {
      DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
          .collection("users")
          .doc(id)
          .get();

      if (documentSnapshot.exists) {
        // Jika dokumen ditemukan, kembalikan datanya sebagai Map
        return documentSnapshot.data() as Map<String, dynamic>;
      } else {
        // Jika tidak ditemukan, kembalikan null
        return null;
      }
    } catch (e) {
      // Tangani jika ada error saat mengambil data
      print("Error getting user info: $e");
      return null;
    }
  }

  // METHOD BARU UNTUK MENAMBAH DATA BIKE
  Future addBike(Map<String, dynamic> bikeData) async {
    return await FirebaseFirestore.instance.collection("Bikes").add(bikeData);
  }

  // Di dalam kelas DatabaseMethod di file service/database.dart
  Future<void> deleteBike(String docId) async {
    return await FirebaseFirestore.instance
        .collection('Bikes')
        .doc(docId)
        .delete();
  }

  // Di dalam kelas DatabaseMethod
  Future<void> updateBike(
    String docId,
    Map<String, dynamic> updatedData,
  ) async {
    return await FirebaseFirestore.instance
        .collection('Bikes')
        .doc(docId)
        .update(updatedData);
  }

  // Di dalam kelas DatabaseMethod
  Future createBooking(Map<String, dynamic> bookingData) async {
    return await FirebaseFirestore.instance
        .collection('bookings')
        .add(bookingData);
  }

  Future<void> updateBookingStatus(String bookingId, String status) async {
    return await FirebaseFirestore.instance
        .collection('bookings')
        .doc(bookingId)
        .update({'status': status});
  }
}

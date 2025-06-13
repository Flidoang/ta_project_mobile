// Lokasi: lib/widgets/wave_clipper.dart

import 'package:flutter/material.dart';

// Kelas ini akan "memotong" widget menjadi bentuk gelombang
class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height * 0.85); // Mulai dari kiri bawah
    path.quadraticBezierTo(
      size.width / 4,
      size.height, // Titik kontrol untuk lengkungan
      size.width / 2,
      size.height * 0.90, // Puncak tengah lengkungan
    );
    path.quadraticBezierTo(
      size.width * 3 / 4,
      size.height * 0.80, // Titik kontrol kedua
      size.width,
      size.height * 0.85, // Titik akhir kanan bawah
    );
    path.lineTo(size.width, 0); // Ke kanan atas
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
  }
}

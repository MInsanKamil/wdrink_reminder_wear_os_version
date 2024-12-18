// Widget indikator persentase
import 'package:flutter/material.dart';

class PercentIndicator extends StatelessWidget {
  final double percentage;

  PercentIndicator({required this.percentage});

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: ArrowClipper(), // CustomClipper untuk bentuk panah
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        color: Colors.blue[500]!, // Warna background biru
        child: Text(
          '${percentage.toStringAsFixed(1)}%', // Menampilkan persentase
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white70, // Warna teks hitam
          ),
        ),
      ),
    );
  }
}

// Custom Clipper untuk bentuk panah
class ArrowClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width - 20, 0); // Garis atas
    path.lineTo(size.width, size.height / 2); // Membentuk panah
    path.lineTo(size.width - 20, size.height); // Garis bawah
    path.lineTo(0, size.height); // Garis bawah kiri
    path.close(); // Menutup path
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
  }
}

class InvertedArrowClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.moveTo(size.width, 0); // Starting point at the top right corner
    path.lineTo(20, 0); // Top line of the arrow
    path.lineTo(0, size.height / 2); // Arrow tip pointing left
    path.lineTo(20, size.height); // Bottom line of the arrow
    path.lineTo(size.width, size.height); // Bottom right corner
    path.close(); // Closing the path
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
  }
}

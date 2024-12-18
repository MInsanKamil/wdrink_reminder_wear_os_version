import 'package:flutter/material.dart';
import 'package:wave/wave.dart';
import 'package:wave/config.dart';

class GlassShapeWidget extends StatelessWidget {
  const GlassShapeWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        CustomPaint(
          size: Size(200, 300), // Ukuran tetap gelas
          painter: GlassPainter(),
        ),
        // Menambahkan animasi wave di dalam gelas
        Positioned(
          bottom: 0,
          child: ClipPath(
            clipper: WaveShape(), // Custom wave sesuai bentuk gelas
            child: WaveWidget(
              config: CustomConfig(
                colors: [Colors.blue.withOpacity(0.7), Colors.blue],
                durations: [6000, 12000],
                heightPercentages: [0.1, 0.15],
                blur: MaskFilter.blur(BlurStyle.solid, 5),
              ),
              size: Size(200, 80), // Ukuran yang sama dengan gelas
              waveAmplitude: 5,
            ),
          ),
        ),
      ],
    );
  }
}

// Custom Clipper untuk bentuk gelas
class WaveShape extends CustomClipper<Path> {
  WaveShape();

  @override
  Path getClip(Size size) {
    double radius = 10.0; // Radius lengkungan di sudut

    Path wavePath = Path();
    // Mulai dari bagian bawah kiri gelas
    wavePath.moveTo(size.width * 0.25, size.height - radius); // Bottom-left

    // Sudut kiri bawah
    wavePath.arcToPoint(
      Offset(size.width * 0.25 + radius, size.height),
      radius: Radius.circular(radius),
      clockwise: false,
    );

    // Garis bawah menuju kanan
    wavePath.lineTo(size.width * 0.75 - radius, size.height);

    // Sudut kanan bawah
    wavePath.arcToPoint(
      Offset(size.width * 0.75, size.height - radius),
      radius: Radius.circular(radius),
      clockwise: false,
    );

    // Garis kanan menuju atas
    wavePath.lineTo(size.width * 0.9, size.height - 150 + radius);

    // Sudut kanan atas
    wavePath.arcToPoint(
      Offset(size.width * 0.9 - radius, size.height - 150),
      radius: Radius.circular(radius),
      clockwise: false,
    );

    // Garis atas menuju kiri
    wavePath.lineTo(size.width * 0.1 + radius, size.height - 150);

    // Sudut kiri atas
    wavePath.arcToPoint(
      Offset(size.width * 0.1, size.height - 150 + radius),
      radius: Radius.circular(radius),
      clockwise: false,
    );

    // Kembali ke titik awal (kiri bawah)
    wavePath.lineTo(size.width * 0.25, size.height - radius);
    wavePath.close();

    return wavePath;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return true;
  }
}

class GlassPainter extends CustomPainter {
  GlassPainter();

  @override
  void paint(Canvas canvas, Size size) {
    double radius = 10.0; // Radius untuk sudut

    Paint paint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.white.withOpacity(0.5), Colors.blue.withOpacity(0.2)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    Path glassPath = Path();
    // Mulai dari bagian bawah kiri gelas
    glassPath.moveTo(size.width * 0.25, size.height - radius); // Bottom-left

    // Sudut kiri bawah
    glassPath.arcToPoint(
      Offset(size.width * 0.25 + radius, size.height),
      radius: Radius.circular(radius),
      clockwise: false,
    );

    // Garis bawah menuju kanan
    glassPath.lineTo(size.width * 0.75 - radius, size.height);

    // Sudut kanan bawah
    glassPath.arcToPoint(
      Offset(size.width * 0.75, size.height - radius),
      radius: Radius.circular(radius),
      clockwise: false,
    );

    // Garis kanan menuju atas
    glassPath.lineTo(size.width * 0.9, size.height - 150 + radius);

    // Sudut kanan atas
    glassPath.arcToPoint(
      Offset(size.width * 0.9 - radius, size.height - 150),
      radius: Radius.circular(radius),
      clockwise: false,
    );

    // Garis atas menuju kiri
    glassPath.lineTo(size.width * 0.1 + radius, size.height - 150);

    // Sudut kiri atas
    glassPath.arcToPoint(
      Offset(size.width * 0.1, size.height - 150 + radius),
      radius: Radius.circular(radius),
      clockwise: false,
    );

    // Kembali ke titik awal (kiri bawah)
    glassPath.lineTo(size.width * 0.25, size.height - radius);
    glassPath.close();

    canvas.drawPath(glassPath, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

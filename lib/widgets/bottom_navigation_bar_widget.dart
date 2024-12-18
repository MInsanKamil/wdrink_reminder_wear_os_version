import 'package:flutter/material.dart';

class BottomNavigationBarWidget extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  BottomNavigationBarWidget({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.blue.withOpacity(0.9),
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.lightBlue[100]!,
      currentIndex: currentIndex, // Menentukan tab yang aktif
      onTap: onTap, // Memanggil callback ketika tab di-klik
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.water_drop),
          label: 'Hari ini',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history),
          label: 'Riwayat',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Saya',
        ),
      ],
    );
  }
}

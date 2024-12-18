import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/history_screen.dart';
import 'screens/profil_screen.dart';
import 'widgets/bottom_navigation_bar_widget.dart';

class MainNavigation extends StatefulWidget {
  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0; // Index untuk BottomNavigationBar

  // Daftar layar yang ditampilkan berdasarkan tab
  final List<Widget> _screens = [
    HomeScreen(), // Layar Home
    HistoryScreen(), // Layar Riwayat
    ProfileScreen()
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index; // Mengubah layar berdasarkan tab yang dipilih
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex], // Menampilkan layar berdasarkan index tab
      bottomNavigationBar: BottomNavigationBarWidget(
        currentIndex: _currentIndex, // Memberikan index yang sedang aktif
        onTap: _onTabTapped, // Memanggil fungsi saat tab di-klik
      ),
    );
  }
}

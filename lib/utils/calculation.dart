int calculateTargetHarian(umur, jenisKelamin) {
  if (umur >= 1 && umur <= 3) return 1300;
  if (umur >= 4 && umur <= 8) return 1700;
  if (umur >= 9 && umur <= 13) {
    return jenisKelamin == 'Laki-laki' ? 2400 : 2100;
  }
  if (umur >= 14 && umur <= 18) {
    return jenisKelamin == 'Laki-laki' ? 3300 : 2300;
  }
  if (umur >= 19) {
    return jenisKelamin == 'Laki-laki' ? 3700 : 2700;
  }
  return 0;
}

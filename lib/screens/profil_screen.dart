import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wdrink_reminder/services/notification_service.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:wdrink_reminder/utils/calculation.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int totalMinum = 0;
  int targetHarian = 0;
  int ml = 0;
  String jenisKelamin = '';
  String errorMessageWaktuTidur = '';
  String errorMessageSelangWaktu = '';
  int umur = 0;
  List<Map<String, dynamic>> _drinkLogs = [];
  List<Map<String, dynamic>> _drinkLog = [];

  // Reminder settings
  int selangWaktu = 30;
  TimeOfDay waktuTidur = TimeOfDay(hour: 23, minute: 0);
  TimeOfDay waktuBangun = TimeOfDay(hour: 8, minute: 0);
  bool isStopReminder = false;
  bool isManualTargetEnabled = false;

  Future<void> _saveNotificationTime(DateTime notificationTime) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> notificationTimes =
        prefs.getStringList('notification_times') ?? [];
    notificationTimes.add(notificationTime.toIso8601String());
    await prefs.setStringList('notification_times', notificationTimes);
  }

  void _scheduleWaterReminders() async {
    // Hapus semua notifikasi lama
    await NotificationHelper.cancelAllNotifications();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('notification_times');
    // Periksa apakah target harian sudah tercapai
    if (ml >= targetHarian) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Target harian sudah tercapai, pengingat dicukupkan hari ini',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Tampilkan dialog loading
    showDialog(
      context: context,
      barrierDismissible: false, // Tidak dapat ditutup saat loading
      builder: (BuildContext context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text(
                  "Menjadwalkan...",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[500],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      // Hitung waktu mulai (waktu bangun) dan waktu akhir (waktu tidur)
      final currentDate = DateTime.now();
      var startTime = tz.TZDateTime.from(
        DateTime(
          currentDate.year,
          currentDate.month,
          currentDate.day,
          waktuBangun.hour,
          waktuBangun.minute,
        ),
        tz.local,
      );
      var endTime = tz.TZDateTime.from(
        DateTime(
          currentDate.year,
          currentDate.month,
          currentDate.day,
          waktuTidur.hour,
          waktuTidur.minute,
        ),
        tz.local,
      );

      // Jika waktu tidur melintasi tengah malam, tambahkan satu hari ke endTime
      if (endTime.isBefore(startTime)) {
        endTime = endTime.add(const Duration(days: 1));
      }

      // Periksa apakah waktu saat ini sudah melewati waktu tidur
      final tzNow = tz.TZDateTime.now(tz.local);
      if (tzNow.isAfter(endTime)) {
        Navigator.pop(context); // Tutup dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saat ini sudah melewati waktu tidur.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Jika sekarang sebelum waktu bangun, mulai dari waktu bangun
      tz.TZDateTime nextNotificationTime =
          tzNow.isBefore(startTime) ? startTime : tzNow;

      // Jadwalkan notifikasi pada selang waktu tertentu di rentang waktu bangun dan tidur
      int notificationCount = 0;
      while (nextNotificationTime.isBefore(endTime)) {
        nextNotificationTime = nextNotificationTime.add(
          Duration(minutes: selangWaktu),
        );

        // Jadwalkan notifikasi
        await NotificationHelper.scheduleNotification(
          'Waktunya Minum Air',
          'Jaga kesehatan Anda dengan minum air sekarang!',
          nextNotificationTime,
        );
        await _saveNotificationTime(nextNotificationTime);

        notificationCount++;

        // Batasi jumlah notifikasi untuk menghindari batas maksimum sistem
        if (notificationCount > 480) {
          throw Exception('Maximum limit of concurrent alarms');
        }
      }

      // Tutup dialog dan tampilkan pesan sukses
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pengingat telah dijadwalkan.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Tangani kesalahan dan tutup dialog
      Navigator.pop(context);
      if (e.toString().contains('Maximum limit of concurrent alarms')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Terlalu banyak notifikasi yang dijadwalkan. Mohon selang waktu jangan terlau pendek'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      await NotificationHelper.cancelAllNotifications();
    }
  }

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _loadTotalMinum();
  }

  Future<void> _loadPreferences() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      setState(() {
        targetHarian = prefs.getInt('targetHarian') ?? targetHarian;
        jenisKelamin = prefs.getString('jenisKelamin') ?? jenisKelamin;
        umur = prefs.getInt('umur') ?? umur;
        isManualTargetEnabled =
            prefs.getBool('isManual') ?? isManualTargetEnabled;
        String? waktuBangunString = prefs.getString('waktuBangun');
        String? waktuTidurString = prefs.getString('waktuTidur');
        selangWaktu = prefs.getInt('selangWaktu') ?? selangWaktu;
        isStopReminder = prefs.getBool('isStopReminder') ?? isStopReminder;

        if (waktuBangunString != null) {
          waktuBangun = TimeOfDay(
            hour: int.parse(waktuBangunString.split(":")[0]),
            minute: int.parse(waktuBangunString.split(":")[1]),
          );
        }

        if (waktuTidurString != null) {
          waktuTidur = TimeOfDay(
            hour: int.parse(waktuTidurString.split(":")[0]),
            minute: int.parse(waktuTidurString.split(":")[1]),
          );
        }
      });
    } catch (e) {
      // Opsional: Menampilkan pesan error kepada pengguna
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Gagal memuat preferensi"),
            backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _loadTotalMinum() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? drinkLog = prefs.getStringList('drinkLog');
    setState(() {
      _drinkLogs = drinkLog!
          .map((log) => jsonDecode(log) as Map<String, dynamic>)
          .toList();

// Update _ml dengan jumlah total minuman dalam semua log
      totalMinum =
          _drinkLogs.fold(0, (sum, log) => sum + (log['volume'] as int));

      _drinkLog = drinkLog
          .map((log) => jsonDecode(log) as Map<String, dynamic>)
          .where((log) {
        DateTime logDate = DateTime.parse(log['time']);
        return logDate.year == DateTime.now().year &&
            logDate.month == DateTime.now().month &&
            logDate.day == DateTime.now().day;
      }).toList();

      // Update _ml dengan jumlah total minuman pada hari tersebut
      ml = _drinkLog.isNotEmpty ? _drinkLog.last['ml'] ?? 0 : 0;
    });
  }

  Future<void> _savePreferences() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt('targetHarian', targetHarian);
      await prefs.setString('jenisKelamin', jenisKelamin);
      await prefs.setInt('umur', umur);
      await prefs.setBool('isManual', isManualTargetEnabled);
      await prefs.setString('waktuBangun', waktuBangun.format(context));
      await prefs.setString('waktuTidur', waktuTidur.format(context));
      await prefs.setInt('selangWaktu', selangWaktu);
      await prefs.setBool('isStopReminder', isStopReminder);
    } catch (e) {
      // Opsional: Menampilkan pesan error kepada pengguna
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Gagal menyimpan preferensi"),
            backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!isManualTargetEnabled) {
      setState(() {
        targetHarian = calculateTargetHarian(umur, jenisKelamin);
      });
    }
    return Scaffold(
      backgroundColor: Colors.lightBlueAccent,
      body: SafeArea(
        child: Container(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Bagian Total Minum dan Total Tercapai
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.blue[500],
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.water_drop_outlined, color: Colors.white),
                          SizedBox(height: 8),
                          Text(
                            '$totalMinum ml',
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                          Text(
                            'Total minum',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
              SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Atur Manual Target Minum Harian',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  Switch(
                    value: isManualTargetEnabled,
                    onChanged: (value) {
                      setState(() async {
                        isManualTargetEnabled = value;
                        if (!isManualTargetEnabled) {
                          // Update target harian secara otomatis jika switch mati
                          targetHarian =
                              calculateTargetHarian(umur, jenisKelamin);
                        }
                        await _savePreferences();
                        await _loadPreferences();
                      });
                    },
                    activeColor: Colors.white,
                    activeTrackColor: Colors.blue[500],
                    inactiveThumbColor: Colors.blue[300],
                    inactiveTrackColor: Colors.white,
                    trackOutlineColor: MaterialStateProperty.all(Colors.blue),
                  ),
                ],
              ),

              // Pengaturan lainnya
              Expanded(
                child: ListView(
                  children: [
                    _buildSettingTile(Icons.notifications, 'Pengingat',
                        onTap: () {
                      _showReminderSettings();
                    }),
                    SizedBox(height: 10),
                    _buildSettingTile(
                      Icons.water_drop,
                      'Target harian',
                      subtitle: '$targetHarian ml',
                      onTap: isManualTargetEnabled
                          ? () => _showEditDialog(
                                  context, 'Target Harian', '$targetHarian',
                                  (value) {
                                // Update tujuan harian
                                setState(() {
                                  targetHarian =
                                      int.tryParse(value) ?? targetHarian;
                                });
                              })
                          : () {}, // Fungsi kosong saat switch mati
                    ),
                    SizedBox(height: 10),
                    _buildSettingTile(
                      Icons.person,
                      'Jenis kelamin',
                      subtitle: '$jenisKelamin',
                      onTap: () => _showGenderSelectionModal(
                          context, jenisKelamin, (value) {
                        // Update jenis kelamin
                        setState(() {
                          jenisKelamin = value;
                          targetHarian = calculateTargetHarian(umur, value);
                        });
                      }),
                    ),
                    SizedBox(height: 10),
                    _buildSettingTile(
                      Icons.calendar_today,
                      'Umur',
                      subtitle: '$umur tahun',
                      onTap: () =>
                          _showEditDialog(context, 'Umur', '$umur', (value) {
                        // Update umur
                        setState(() {
                          umur = int.tryParse(value) ?? umur;
                          targetHarian = calculateTargetHarian(
                              umur, int.tryParse(value) ?? umur);
                        });
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingTile(IconData icon, String title,
      {String? subtitle, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: TextStyle(color: Colors.white)),
      subtitle: subtitle != null
          ? Text(subtitle, style: TextStyle(color: Colors.white70))
          : null,
      trailing: title == 'Target harian' && !isManualTargetEnabled
          ? null // Trailing hilang jika Target harian dan isManualTargetEnabled == false
          : Icon(Icons.arrow_forward_ios,
              color: Colors
                  .white), // Menampilkan trailing yang diberikan kecuali untuk Target harian
      contentPadding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
      tileColor: Colors.blue[500],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      onTap: onTap,
    );
  }

  void _showGenderSelectionModal(
      BuildContext context, String currentValue, Function(String) onUpdate) {
    final List<String> genderOptions = ['Laki-laki', 'Perempuan'];
    String selectedValue = currentValue;

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Pilih Jenis Kelamin',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[500]),
              ),
            ),
            Divider(),
            Column(
              children: genderOptions.map((String value) {
                return RadioListTile<String>(
                  title: Text(value, style: TextStyle(color: Colors.blue[500])),
                  value: value,
                  groupValue: selectedValue,
                  activeColor: Colors.blue[500],
                  onChanged: (String? newValue) async {
                    if (newValue != null) {
                      showDialog(
                        context: context,
                        barrierDismissible:
                            false, // Tidak dapat ditutup saat loading
                        builder: (BuildContext context) {
                          return Dialog(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(width: 20),
                                  Text("Menyimpan...",
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue[500])),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                      setState(() {
                        selectedValue = newValue;
                        onUpdate(newValue); // Update the selected value
                      });

                      await _savePreferences();
                      await _loadPreferences();
                      Navigator.of(context).pop();
                      Navigator.of(context).pop(); // Close the modal
                    }
                  },
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, String title, String currentValue,
      Function(String) onUpdate) {
    final TextEditingController controller =
        TextEditingController(text: currentValue);

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context)
                .viewInsets
                .bottom, // Mengatur agar tidak tertutup keyboard
          ),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                      color: Colors.blue[500],
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: "Masukkan $title",
                    hintStyle: TextStyle(color: Colors.blue[500]),
                    enabledBorder: UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: Colors.blue[500]!), // Custom color
                    ),
                    // Customize the underline when the field is focused
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                          color: Colors.blue[700]!,
                          width: 2.0), // Custom color and width
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () async {
                        showDialog(
                          context: context,
                          barrierDismissible:
                              false, // Tidak dapat ditutup saat loading
                          builder: (BuildContext context) {
                            return Dialog(
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(),
                                    SizedBox(width: 20),
                                    Text("Menyimpan...",
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue[500])),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                        onUpdate(controller.text);
                        await _savePreferences();
                        await _loadPreferences();
                        Navigator.of(context).pop();
                        Navigator.of(context).pop();
                      },
                      child: Text('Simpan',
                          style: TextStyle(color: Colors.blue[500])),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text('Batal',
                          style: TextStyle(color: Colors.blue[500])),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showReminderSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white70,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateModal) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white70,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.0),
                  topRight: Radius.circular(20.0),
                ),
              ),
              padding: EdgeInsets.all(20.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pengaturan Pengingat',
                      style: TextStyle(
                        color: Colors.blue[500],
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Selang Waktu (menit)',
                      style: TextStyle(
                        color: Colors.blue[500],
                        fontSize: 16,
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 7),
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.blue[500] ?? Colors.blue,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TextField(
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintStyle: TextStyle(color: Colors.blue[300]),
                          hintText: 'Masukkan selang waktu (contoh: 30)',
                        ),
                        onChanged: (value) {
                          setStateModal(() {
                            selangWaktu = int.tryParse(value) ?? selangWaktu;
                            if (selangWaktu <= 0) {
                              errorMessageSelangWaktu =
                                  'Selang waktu harus lebih besar dari 0';
                            } else if (selangWaktu > 0) {
                              errorMessageSelangWaktu = '';
                            }
                          });
                        },
                      ),
                    ),
                    if (errorMessageSelangWaktu.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 1.0),
                        child: Text(
                          errorMessageSelangWaktu,
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    SizedBox(height: 10),
                    Text(
                      'Waktu Tidur',
                      style: TextStyle(
                        color: Colors.blue[500],
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 10),
                    _buildTimePicker(
                      context,
                      'Dari: ${waktuTidur.format(context)}',
                      waktuTidur,
                      (picked) {
                        if (picked != null) {
                          setStateModal(() {
                            waktuTidur = picked;
                            if (waktuTidur != waktuBangun) {
                              errorMessageWaktuTidur = '';
                            }
                          });
                        }
                      },
                    ),
                    SizedBox(height: 5),
                    _buildTimePicker(
                      context,
                      'Hingga: ${waktuBangun.format(context)}',
                      waktuBangun,
                      (picked) {
                        if (picked != null) {
                          setStateModal(() {
                            waktuBangun = picked;
                            if (waktuTidur != waktuBangun) {
                              errorMessageWaktuTidur = '';
                            }
                          });
                        }
                      },
                    ),
                    if (errorMessageWaktuTidur.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 1.0),
                        child: Text(
                          errorMessageWaktuTidur,
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Hentikan ketika target tercapai',
                            style: TextStyle(
                              color: Colors.blue[500],
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Switch(
                          value: isStopReminder,
                          activeColor: Colors.blue[300],
                          activeTrackColor: Colors.blue[700],
                          inactiveThumbColor: Colors.blue[300],
                          inactiveTrackColor: Colors.white70,
                          onChanged: (value) {
                            setStateModal(() {
                              isStopReminder = value;
                            });
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Center(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[500],
                        ),
                        onPressed: () async {
                          // Validasi data sebelum menyimpan
                          if (waktuBangun == waktuTidur) {
                            setStateModal(() {
                              errorMessageWaktuTidur =
                                  'Waktu tidur dan waktu bangun harus berbeda';
                            });
                            return;
                          }

                          // Jadwalkan ulang pengingat
                          _scheduleWaterReminders();
                          _savePreferences();

                          // Tutup modal
                          Navigator.pop(context);
                        },
                        child: Text(
                          'Simpan',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTimePicker(
    BuildContext context,
    String title,
    TimeOfDay initialTime,
    Function(TimeOfDay?) onPicked,
  ) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.blue[500] ?? Colors.blue,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        title: Text(
          title,
          style: TextStyle(color: Colors.blue[500]),
        ),
        trailing: Icon(Icons.edit, color: Colors.blue[500]),
        onTap: () async {
          TimeOfDay? picked = await showTimePicker(
            context: context,
            initialTime: initialTime,
          );

          onPicked(picked);
        },
      ),
    );
  }
}

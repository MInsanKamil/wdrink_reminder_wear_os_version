import 'dart:math';
import 'dart:convert'; // Untuk encode/decode list ke string
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wdrink_reminder/services/notification_service.dart';
import '../models/drinklog.dart';
import '../widgets/glass_shape_widget.dart';
import '../widgets/percent_indikator_widget.dart';
import 'package:wave/wave.dart';
import 'package:wave/config.dart';

// undo, atur supaya ketika minum, sekalian atur volume air
class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _ml = 0;
  int _waveHeight = 150;
  int _volume = 200;
  int _target = 0;
  String errorMessage = '';
  bool isStopReminder = false;
  double _waveAmplitude = 10;
  late Future<DateTime?> _nextNotificationFuture;
  @override
  void initState() {
    super.initState();
    _loadLatestDrinkLog();
    _loadTargetHarian();
    _loadPreferences();
    _nextNotificationFuture = _getNextNotificationTime();
  }

  Future<DateTime?> _getNextNotificationTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> notificationTimes =
          prefs.getStringList('notification_times') ?? [];

      if (notificationTimes.isNotEmpty) {
        // Parse semua waktu notifikasi
        List<DateTime> parsedTimes = notificationTimes
            .map((time) => DateTime.parse(time).toLocal())
            .toList();

        // Filter waktu yang sudah lewat
        DateTime now = DateTime.now();
        parsedTimes.removeWhere((time) => time.isBefore(now));

        // Update daftar waktu yang masih valid ke SharedPreferences
        await prefs.setStringList(
          'notification_times',
          parsedTimes.map((time) => time.toUtc().toIso8601String()).toList(),
        );

        if (parsedTimes.isNotEmpty) {
          // Ambil waktu terdekat yang tersisa
          DateTime nextTime = parsedTimes.first;
          return nextTime;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _loadPreferences() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      setState(() {
        isStopReminder = prefs.getBool('isStopReminder') ?? isStopReminder;
      });
    } catch (e) {
      // Opsional: Menampilkan pesan error kepada pengguna
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal memuat preferensi"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _loadTargetHarian() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _target = prefs.getInt('targetHarian') ?? _target;
    });
  }

  void _increaseDrink() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (_ml >= _target) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Anda sudah mencapai batas target harian"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _ml += _volume;
      _waveHeight += (_volume / 10).round();
      _waveAmplitude += (_volume / 40).round();
    });

    // Mendapatkan waktu saat ini
    DateTime now = DateTime.now();
    // String formattedTime = "${now.hour}:${now.minute}";
    // String formattedDate = "${now.day}-${now.month}-${now.year}";

    // Simpan data ke dalam list
    List<String> drinkLog = prefs.getStringList('drinkLog') ?? [];
    String logEntry = jsonEncode({
      'volume': _volume,
      'time': now.toIso8601String(), // Store the date in ISO 8601 format
      'ml': _ml,
      'waveHeight': _waveHeight,
      'waveAmplitude': _waveAmplitude,
    });
    drinkLog.add(logEntry);

    // Simpan kembali ke SharedPreferences
    await prefs.setStringList('drinkLog', drinkLog);

    if (isStopReminder && _ml >= _target) {
      await NotificationHelper.cancelAllNotifications();
      await prefs.remove('notification_times');
      setState(() {
        _nextNotificationFuture = _getNextNotificationTime();
      });
    }
  }

  void _undoDrink() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> drinkLog = prefs.getStringList('drinkLog') ?? [];

    // Filter logs for today
    DateTime today = DateTime.now();
    String todayString =
        DateTime(today.year, today.month, today.day).toIso8601String();

    // Remove the latest log for today
    if (drinkLog.isNotEmpty) {
      Map<String, dynamic> lastLog = jsonDecode(drinkLog.last);
      DateTime logDate = DateTime.parse(lastLog['time']);
      String logDateString =
          DateTime(logDate.year, logDate.month, logDate.day).toIso8601String();

      if (logDateString == todayString) {
        drinkLog.removeLast(); // Remove the last log
        await prefs.setStringList('drinkLog', drinkLog); // Save back

        // Update state
        int lastMl = lastLog['ml'] as int;
        int lastVolume = lastLog['volume'] as int; // Cast to int
        setState(() {
          _ml -= lastVolume; // Update _ml
          _waveHeight -= (lastVolume / 10).round() as int; // Update wave height
          _waveAmplitude -=
              (lastVolume / 40).round() as int; // Update wave amplitude
        });
      }
    }
  }

  void _loadLatestDrinkLog() async {
    // Nilai default
    int defaultMl = 0;
    int defaultVolume = 200;
    int defaultWaveHeight = 150;
    double defaultWaveAmplitude = 10;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? drinkLog = prefs.getStringList('drinkLog');

    Drinkslog latestTodayLog;

    if (drinkLog != null && drinkLog.isNotEmpty) {
      DateTime today = DateTime.now();
      latestTodayLog = drinkLog.reversed
          .map((entry) => Drinkslog.fromJson(jsonDecode(entry)))
          .firstWhere(
        (log) {
          DateTime logDate = DateTime.parse(log.time);
          return logDate.year == today.year &&
              logDate.month == today.month &&
              logDate.day == today.day;
        },
        orElse: () => Drinkslog(
          volume: defaultVolume,
          time: today.toIso8601String(),
          ml: defaultMl,
          waveHeight: defaultWaveHeight,
          waveAmplitude: defaultWaveAmplitude,
        ),
      );
    } else {
      // Jika tidak ada log sama sekali, gunakan objek default
      latestTodayLog = Drinkslog(
        volume: defaultVolume,
        time: DateTime.now().toIso8601String(),
        ml: defaultMl,
        waveHeight: defaultWaveHeight,
        waveAmplitude: defaultWaveAmplitude,
      );
    }

    setState(() {
      _ml = latestTodayLog.ml;
      _volume = latestTodayLog.volume;
      _waveHeight = latestTodayLog.waveHeight;
      _waveAmplitude = latestTodayLog.waveAmplitude;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Mendapatkan ukuran layar
    final size = MediaQuery.of(context).size;
    _loadTargetHarian();
    return Scaffold(
      backgroundColor: Colors.lightBlueAccent,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: size.height * 0.05),
            TweenAnimationBuilder<int>(
              tween: IntTween(begin: max(_ml - _volume, 0), end: _ml),
              duration: Duration(milliseconds: 1000),
              builder: (context, value, child) {
                return RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '$value', // Angka "value"
                        style: TextStyle(
                          fontSize: size.width *
                              0.15, // Ukuran font berdasarkan lebar layar
                          fontWeight: FontWeight.bold,
                          color: Colors.white70,
                        ),
                      ),
                      TextSpan(
                        text: ' ml', // Satuan "ml"
                        style: TextStyle(
                          fontSize: size.width *
                              0.05, // Ukuran font lebih kecil berdasarkan lebar layar
                          fontWeight: FontWeight.normal,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            SizedBox(
                height: size.height * 0.01), // Jarak vertikal lebih responsif
            Text(
              'Target Harian: $_target ml',
              style: TextStyle(
                fontSize: size.width * 0.05,
                color: Colors.white70,
              ),
            ),
            SizedBox(height: size.height * 0.01),
            FutureBuilder<DateTime?>(
              future: _nextNotificationFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator(color: Colors.blue[500]);
                } else if (snapshot.hasError) {
                  return Text(
                    'Error: ${snapshot.error}',
                    style: TextStyle(fontSize: 16, color: Colors.red),
                  );
                } else if (snapshot.hasData) {
                  final nextNotificationTime = snapshot.data!;
                  final formattedTime =
                      DateFormat('HH:mm').format(nextNotificationTime);
                  final now = DateTime.now();
                  final isTomorrow = nextNotificationTime.year > now.year ||
                      (nextNotificationTime.year == now.year &&
                          (nextNotificationTime.month > now.month ||
                              (nextNotificationTime.month == now.month &&
                                  nextNotificationTime.day > now.day)));

                  return Text(
                    'Pengingat Berikutnya: Pukul $formattedTime, ${isTomorrow ? 'Besok' : 'Hari Ini'}',
                    style: TextStyle(
                      fontSize: size.width * 0.04,
                      color: Colors.white70,
                    ),
                  );
                } else {
                  return Text(
                    'Tidak ada pengingat yang dijadwalkan',
                    style: TextStyle(
                      fontSize: size.width * 0.04,
                      color: Colors.white70,
                    ),
                  );
                }
              },
            ),
            SizedBox(height: size.height * 0.01),
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                      color: Colors.transparent,
                      height: double.parse(_waveHeight.toString()),
                      child: WaveWidget(
                        config: CustomConfig(
                          colors: [
                            Colors.blue.withOpacity(0.1),
                            Colors.blue.withOpacity(0.3),
                            Colors.blue.withOpacity(0.5),
                          ],
                          durations: [3000, 6000, 12000],
                          heightPercentages: [0.15, 0.20, 0.25],
                          blur: MaskFilter.blur(BlurStyle.solid, 10),
                        ),
                        size: Size(double.infinity,
                            double.parse(_waveHeight.toString())),
                        waveAmplitude: _waveAmplitude,
                      ),
                    ),
                  ),
                  Positioned(
                      bottom: size.height * 0.12, child: GlassShapeWidget()),
                  Positioned(
                    bottom: size.height * 0.22,
                    child: Text(
                      '$_volume ml',
                      style: TextStyle(
                        fontSize: size.width * 0.05,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: size.height * 0.125,
                    child: ElevatedButton(
                      onPressed: _showVolumeDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.lightBlue[500]!,
                        padding: EdgeInsets.symmetric(
                          horizontal: size.width * 0.03,
                          vertical: size.height * 0.01,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        'Atur Volume Air',
                        style: TextStyle(
                          fontSize: size.width * 0.03,
                          fontWeight: FontWeight.bold,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            onPressed: _increaseDrink,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.lightBlue[500]!,
                              padding: EdgeInsets.symmetric(
                                horizontal: size.width * 0.08,
                                vertical: size.height * 0.02,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: Text(
                              '+ MINUM',
                              style: TextStyle(
                                fontFamily: 'RobotoMono',
                                fontSize: size.width * 0.05,
                                fontWeight: FontWeight.bold,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                          SizedBox(height: size.height * 0.03),
                        ],
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        PercentIndicator(
                            percentage: min((_ml / _target) * 100, 100)),
                        SizedBox(height: size.height * 0.25),
                      ],
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ClipPath(
                          clipper: InvertedArrowClipper(),
                          child: ElevatedButton(
                            onPressed: _undoDrink,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(255, 247, 96, 96),
                              padding: EdgeInsets.only(
                                left: size.width * 0.05,
                                right: size.width * 0.01,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(0),
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'BATAL MINUM',
                                  style: TextStyle(
                                    fontFamily: 'RobotoMono',
                                    fontSize: size.width * 0.04,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: size.height * 0.35),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showVolumeDialog() async {
    int? newVolume = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled:
          true, // Untuk mengizinkan dialog memenuhi layar lebih banyak jika diperlukan
      builder: (BuildContext context) {
        int tempVolume = _volume;
        return StatefulBuilder(builder: (context, setStateModal) {
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
                children: <Widget>[
                  Text(
                    'Atur Volume Air',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[500]),
                  ),
                  TextField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: "Masukkan volume air (ml)",
                      hintStyle: TextStyle(color: Colors.blue[500]),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                            color: Colors.blue[500]!), // Custom color
                      ),
                      // Customize the underline when the field is focused
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                            color: Colors.blue[700]!,
                            width: 2.0), // Custom color and width
                      ),
                    ),
                    onChanged: (value) {
                      if (int.tryParse(value)! <= 0) {
                        setStateModal(() {
                          errorMessage =
                              "Volume air harus lebih besar dari 0 ml";
                        });
                      } else if (int.tryParse(value)! <= _target) {
                        tempVolume = int.tryParse(value) ?? tempVolume;
                        setStateModal(() {
                          errorMessage = ''; // Clear error message
                        });
                      } else {
                        setStateModal(() {
                          errorMessage =
                              "Volume air harus lebih kecil dari target harian";
                        });
                      }
                    },
                  ),
                  if (errorMessage.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 1.0),
                      child: Text(
                        errorMessage,
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      TextButton(
                        child: Text('Batal',
                            style: TextStyle(color: Colors.blue[500])),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      TextButton(
                        child: Text('Simpan',
                            style: TextStyle(color: Colors.blue[500])),
                        onPressed: () {
                          Navigator.of(context).pop(tempVolume);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        });
      },
    );

    if (newVolume != null) {
      setState(() {
        _volume = newVolume;
      });
    }
  }
}

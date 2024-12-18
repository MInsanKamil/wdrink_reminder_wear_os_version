import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wdrink_reminder/app.dart';
import 'package:wdrink_reminder/utils/calculation.dart';

class OnboardingScreenManager extends StatefulWidget {
  @override
  _OnboardingScreenManagerState createState() =>
      _OnboardingScreenManagerState();
}

class _OnboardingScreenManagerState extends State<OnboardingScreenManager> {
  String? jenisKelamin;
  int? umur;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkPreferences();
  }

  Future<void> _checkPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      jenisKelamin = prefs.getString('jenisKelamin');
      umur = prefs.getInt('umur');
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      // Tampilkan layar loading atau placeholder saat data sedang dimuat
      return Scaffold(
        backgroundColor: Colors.lightBlueAccent,
      );
    }

    if (jenisKelamin != null || umur != null) {
      return MainNavigation();
    } else {
      return GenderAndAgeOnboardingScreen(
        onComplete: _saveUserData,
      );
    }
  }

  Future<void> _saveUserData(String gender, int age) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('jenisKelamin', gender);
    await prefs.setInt('umur', age);
    await prefs.setInt('targetHarian', calculateTargetHarian(age, gender));
  }
}

class GenderAndAgeOnboardingScreen extends StatefulWidget {
  final Function(String, int) onComplete;

  GenderAndAgeOnboardingScreen({required this.onComplete});

  @override
  _GenderAndAgeOnboardingScreenState createState() =>
      _GenderAndAgeOnboardingScreenState();
}

class _GenderAndAgeOnboardingScreenState
    extends State<GenderAndAgeOnboardingScreen> {
  String? selectedGender;
  int? selectedAge;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlueAccent,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/icon.png', // Path to your launcher icon
                        width: 200, // Adjust the width of the icon
                        height: 200, // Adjust the height of the icon
                      ),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20.0),
                          child: Text(
                            'Masukkan Jenis Kelamin Dan Umur, Untuk Menentukan Target Minum Harian Anda',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontStyle: FontStyle.italic,
                              letterSpacing: 1.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      // Gender selection
                      _buildSettingTile(
                        Icons.person,
                        'Jenis kelamin',
                        subtitle: selectedGender ?? 'Pilih jenis kelamin',
                        onTap: () => _showGenderSelectionModal(
                            context, selectedGender, (value) {
                          setState(() {
                            selectedGender = value;
                          });
                        }),
                      ),
                      SizedBox(height: 10),

                      // Age input
                      _buildSettingTile(
                        Icons.calendar_today,
                        'Umur',
                        subtitle: selectedAge != null
                            ? '$selectedAge tahun'
                            : 'Masukkan umur',
                        onTap: () => _showEditDialog(context, 'Umur',
                            selectedAge != null ? '$selectedAge' : '', (value) {
                          setState(() {
                            selectedAge = int.tryParse(value);
                          });
                        }),
                      ),
                      SizedBox(height: 20),

                      // Save button
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[500]),
                        onPressed: () {
                          if (selectedGender != null && selectedAge != null) {
                            widget.onComplete(selectedGender!, selectedAge!);
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => MainNavigation()),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Pilih semua data!'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        child: Text('Lanjut',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
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
      trailing: Icon(Icons.arrow_forward_ios, color: Colors.white),
      contentPadding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
      tileColor: Colors.blue[500],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      onTap: onTap,
    );
  }

  void _showGenderSelectionModal(
      BuildContext context, String? currentValue, Function(String) onUpdate) {
    final List<String> genderOptions = ['Laki-laki', 'Perempuan'];
    String? selectedValue = currentValue;

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
            ...genderOptions.map((String value) {
              return RadioListTile<String>(
                title: Text(value, style: TextStyle(color: Colors.blue[500])),
                value: value,
                groupValue: selectedValue,
                activeColor: Colors.blue[500],
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      selectedValue = newValue;
                    });
                    onUpdate(newValue); // Update the selected gender
                    Navigator.of(context).pop(); // Close the modal
                  }
                },
              );
            }).toList(),
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
            bottom: MediaQuery.of(context).viewInsets.bottom,
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
                SizedBox(height: 10),
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: "Masukkan $title",
                    hintStyle: TextStyle(color: Colors.blue[500]),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue[500]!),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: Colors.blue[700]!, width: 2.0),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        onUpdate(controller.text);
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
}

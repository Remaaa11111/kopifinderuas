import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _filterHarga = 'Semua';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  void _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _filterHarga = prefs.getString('filterHarga') ?? 'Semua';
    });
  }

  void _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('filterHarga', _filterHarga);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Pengaturan disimpan.')));
  }

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final _isDarkMode = themeProvider.isDarkMode;
    final backgroundColor = _isDarkMode ? Color(0xFF23272E) : Colors.white;
    final cardColor = _isDarkMode ? Color(0xFF3E2723) : Colors.white;
    final textColor = _isDarkMode ? Colors.white : Colors.black;
    final iconColor = _isDarkMode ? Colors.amber : Color(0xFF6F4E37);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('Pengaturan', style: TextStyle(color: textColor)),
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Center(
            child: Column(
              children: [
                if (user?.photoURL != null)
                  CircleAvatar(
                    radius: 48,
                    backgroundImage: NetworkImage(user!.photoURL!),
                  )
                else
                  CircleAvatar(radius: 48, child: Icon(Icons.person, size: 48)),
                SizedBox(height: 16),
                Text(
                  user?.displayName ?? 'Tidak ada nama',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  user?.email ?? '',
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
                SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () async {
                    await _logout(context);
                  },
                  icon: Icon(Icons.logout),
                  label: Text('Logout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          // Dark Mode
          Card(
            color: cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              leading: Icon(
                _isDarkMode ? Icons.dark_mode : Icons.light_mode,
                color: iconColor,
              ),
              title: Text(
                'Mode Gelap',
                style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
              ),
              trailing: Switch(
                value: _isDarkMode,
                onChanged: (val) => themeProvider.toggleTheme(val),
                activeColor: iconColor,
              ),
            ),
          ),
          SizedBox(height: 20),
          // Filter Harga
          Card(
            color: cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              leading: Icon(Icons.filter_alt, color: iconColor),
              title: Text(
                'Filter Harga',
                style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
              ),
              subtitle: DropdownButton<String>(
                value: _filterHarga,
                items:
                    ['Semua', 'Murah', 'Sedang', 'Mahal'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _filterHarga = newValue!;
                  });
                  _savePrefs();
                },
              ),
            ),
          ),
          SizedBox(height: 20),
          // Rating Aplikasi
          Card(
            color: cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              leading: Icon(Icons.star_rate, color: Colors.amber),
              title: Text(
                'Beri Rating Aplikasi',
                style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
              ),
              onTap: () async {
                showDialog(
                  context: context,
                  builder: (context) {
                    double _rating = 5;
                    return AlertDialog(
                      title: Text('Beri Rating'),
                      content: StatefulBuilder(
                        builder: (context, setState) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Seberapa puas Anda dengan aplikasi ini?'),
                              SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(5, (index) {
                                  return IconButton(
                                    icon: Icon(
                                      index < _rating
                                          ? Icons.star
                                          : Icons.star_border,
                                      color: Colors.amber,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _rating = index + 1.0;
                                      });
                                    },
                                  );
                                }),
                              ),
                            ],
                          );
                        },
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Batal'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Terima kasih atas rating $_rating bintang!',
                                ),
                              ),
                            );
                          },
                          child: Text('Kirim'),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          SizedBox(height: 20),
          // Tentang Aplikasi
          Card(
            color: cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: iconColor, size: 32),
                      SizedBox(width: 12),
                      Text(
                        'Tentang Aplikasi',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    'KopiFinder',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Versi 1.0.0',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Aplikasi untuk menemukan kedai kopi terbaik di sekitarmu. Temukan, review, dan nikmati kopi favoritmu!',
                    style: TextStyle(fontSize: 15, color: textColor),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/theme.dart';
import 'screens/home_screen.dart';

void main() async { 
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('productBox'); // Box for products
  await Hive.openBox('settingsBox'); // Box for loyalty/settings
  runApp(const CoffeeShopApp()); 
}

class CoffeeShopApp extends StatefulWidget {
  const CoffeeShopApp({super.key});

  @override
  State<CoffeeShopApp> createState() => _CoffeeShopAppState();
}

class _CoffeeShopAppState extends State<CoffeeShopApp> {
  bool isDarkMode = false;

  void toggleTheme() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ILa HomeBar&Coffee', // ✨ ชื่อโปรเจกต์ใหม่!
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: PosScreen(
        isDarkMode: isDarkMode,
        toggleTheme: toggleTheme,
      ),
    );
  }
}

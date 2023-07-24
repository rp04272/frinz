import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:frinz/register.dart';
import 'package:frinz/user.dart';

import 'login.dart';
 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseAuth.instance.authStateChanges().listen((User? user) {
    if (user == null) {
      
    } else {
      
    }
  });
  runApp(MyApp());
}
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FRINZ',
      initialRoute: '/login',
      onGenerateRoute: (settings) {
        if (settings.name == '/login') {
          return MaterialPageRoute(builder: (context) => LoginScreen());
        } else if (settings.name == '/register') {
          return MaterialPageRoute(builder: (context) => RegisterScreen());
        } else if (settings.name == '/user_personal_page') {
          
          final userEmail = settings.arguments as String;
          return MaterialPageRoute(builder: (context) => UserPersonalPage(userEmail: userEmail));
        }
        return null;
      },
    );
  }
}

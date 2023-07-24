import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  void register(BuildContext context) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      // Store additional user data in Firestore collection
      await FirebaseFirestore.instance.collection('Frinz').doc(userCredential.user!.uid).set({
        'email': emailController.text,
        // Add more fields as per your requirements
      });

      // Handle successful registration, navigate to the user's personal page
      Navigator.pushReplacementNamed(context, '/user_personal_page', arguments: userCredential.user!.email);
    } catch (e) {
      // Handle registration errors (e.g., email already exists, weak password)
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Registration failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Register')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(controller: emailController, decoration: InputDecoration(labelText: 'Email')),
            TextFormField(
              controller: passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true, // Set obscureText to true to hide the password characters
            ),
            ElevatedButton(onPressed: () => register(context), child: Text('Register')),
          ],
        ),
      ),
    );
  }
}



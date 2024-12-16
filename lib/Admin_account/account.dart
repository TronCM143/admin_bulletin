import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AccountPage extends StatefulWidget {
  final String username;

  const AccountPage({super.key, required this.username});

  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  bool _isPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  String? _password; // Stores the fetched password
  final TextEditingController _newPasswordController =
      TextEditingController(); // Controller for new password

  @override
  void initState() {
    super.initState();
    _fetchPasswordFromFirebase();
  }

  // Fetch password from Firebase
  Future<void> _fetchPasswordFromFirebase() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('admin')
          .doc(widget.username)
          .get();

      if (userDoc.exists) {
        setState(() {
          _password = userDoc['password'];
        });
      } else {
        print('User not found');
      }
    } catch (error) {
      print('Error fetching password: $error');
    }
  }

  // Update password in Firebase
  Future<void> _updatePasswordInFirebase() async {
    if (_newPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a new password')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('admin')
          .doc(widget.username)
          .update({'password': _newPasswordController.text});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully')),
      );
    } catch (error) {
      print('Error updating password: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update password: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
                'assets/logo_ndmu.png'), // Replace with your image path
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.white.withOpacity(0.1), // Adjust opacity here (0.0 to 1.0)
              BlendMode
                  .dstATop, // Use dstATop to apply opacity on top of the image
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'name: ${widget.username}',
                style: const TextStyle(fontSize: 20, color: Colors.black),
              ),
              const SizedBox(height: 20),
              const Text(
                'Current Password:',
                style: TextStyle(fontSize: 18, color: Colors.black),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: TextEditingController(text: _password),
                obscureText: !_isPasswordVisible,
                readOnly: true,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  hintStyle: TextStyle(color: Colors.black),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.5),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.green,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'New Password:',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _newPasswordController,
                obscureText: !_isNewPasswordVisible,
                decoration: InputDecoration(
                  hintText: 'Enter your new password',
                  hintStyle: TextStyle(color: Colors.black),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.5),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isNewPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.green,
                    ),
                    onPressed: () {
                      setState(() {
                        _isNewPasswordVisible = !_isNewPasswordVisible;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updatePasswordInFirebase,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent.withOpacity(0.8),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Change Password'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

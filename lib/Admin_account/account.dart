import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AccountPage extends StatefulWidget {
  final String username;

  const AccountPage({super.key, required this.username});

  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  bool _isPasswordVisible = false; // Controls password visibility
  bool _isNewPasswordVisible = false; // Controls new password visibility
  String _password = ''; // Stores the fetched password
  String _newPassword = ''; // Stores the new password input
// To control the password TextField
  final _newPasswordController =
      TextEditingController(); // To control the new password TextField

  @override
  void initState() {
    super.initState();
    _fetchPasswordFromFirebase();
  }

  // Fetch password from Firebase
  Future<void> _fetchPasswordFromFirebase() async {
    try {
      // Assuming you have a 'users' collection and each user document is named by their username
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('admin')
          .doc(widget.username)
          .get();

      if (userDoc.exists) {
        setState(() {
          _password = userDoc[
              'password']; // Assuming the password is stored as a plain text string
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
    if (_newPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a new password')),
      );
      return;
    }

    try {
      // Update the password in Firebase
      await FirebaseFirestore.instance
          .collection('admin')
          .doc(widget.username)
          .update({'password': _newPassword});

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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Username: ${widget.username}',
                style: TextStyle(fontSize: 20)),
            SizedBox(height: 20),

            Text('Admin ID: ${widget.username}',
                style: TextStyle(fontSize: 20)),
            SizedBox(height: 20),
            // Current Password Field with toggle visibility
            Text('Current Password:', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            TextField(
              controller: TextEditingController(text: _password),
              obscureText: !_isPasswordVisible, // Toggle visibility
              readOnly: true, // Make it non-editable
              decoration: InputDecoration(
                hintText: '••••••••',
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
            SizedBox(height: 20),

            // New Password Field with toggle visibility
            Text('New Password:', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            TextField(
              controller: _newPasswordController,
              obscureText:
                  _isNewPasswordVisible, // Toggle visibility for new password
              onChanged: (value) {
                setState(() {
                  _newPassword = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Enter your new password',
              ),
            ),
            SizedBox(height: 20),

            // Change Password Button
            ElevatedButton(
              onPressed: _updatePasswordInFirebase,
              child: const Text('Change Password'),
            ),
          ],
        ),
      ),
    );
  }
}

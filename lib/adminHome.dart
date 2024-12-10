import 'package:bulletin_admin/Admin_account/account.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'Post/mainPost.dart'; // A new widget to display all posts with labels
import 'package:bulletin_admin/Account_verification/account_verity.dart';
import 'dart:html' as html;

class AdminHome extends StatefulWidget {
  final String username;

  const AdminHome({super.key, required this.username});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _selectedIndex = 0; // Tracks the selected panel option

  // Widgets for each page
  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _pages.addAll([
      Post(username: widget.username),
      AccountVerification(username: widget.username),
      AccountPage(username: widget.username)
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade600,
        elevation: 0,
        title: const Text(
          'AppDate',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Background Image with transparency
          Positioned.fill(
            child: Opacity(
              opacity: 0.1, // Adjust transparency (0.0 to 1.0)
              child: Image.asset(
                'assets/logo_ndmu.png',
                alignment: Alignment.center, // Centers the image
              ),
            ),
          ),
          // Main Content
          Row(
            children: [
              // Left-side navigation panel
              Container(
                width: 200, // Standard width for the traditional panel
                color: Colors.grey.shade200
                    .withOpacity(0.9), // Slight transparency
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Traditional clickable text items for navigation
                    _buildNavText("Posts", 0),
                    _buildNavText("Account Verification", 1),
                    const Spacer(), // Space between the main options and bottom options
                    // Settings, About, and Account moved to the bottom
                    _buildNavText("Account", 2),
                    // Logout button with traditional style
                    TextButton(
                      onPressed: () {
                        // Reload the web page to simulate a restart
                        html.window.location.reload();
                      },
                      child: const Text(
                        "Logout",
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Main content
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _pages[_selectedIndex],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Custom method to build traditional text navigation items
  Widget _buildNavText(String label, int index) {
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          label,
          style: TextStyle(
            color:
                _selectedIndex == index ? Colors.green.shade600 : Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

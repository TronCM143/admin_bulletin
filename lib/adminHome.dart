import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'dart:html' as html;
import 'Posts/post.dart';
import 'Account_verification/account_verity.dart';
import 'Admin_account/account.dart';
import 'Students/student_table.dart';
import 'calendar.dart';

class AdminHome extends StatefulWidget {
  final String username;

  const AdminHome({super.key, required this.username});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [];
  bool isDSA = false; // Flag to check if the user is 'DSA'

  @override
  void initState() {
    super.initState();
    _initializePages();
  }

  Future<void> _initializePages() async {
    // Fetch the user's role from Firestore
    DocumentSnapshot adminSnapshot = await FirebaseFirestore.instance
        .collection('admin')
        .doc(widget.username)
        .get();

    if (adminSnapshot.exists) {
      var adminData = adminSnapshot.data() as Map<String, dynamic>;
      String userRole = adminData['name'] ?? '';

      setState(() {
        isDSA = userRole == 'DSA'; // Check if the role is 'DSA'

        // Add pages based on user role
        _pages.addAll([
          Posts(username: widget.username),
          // Only add AccountVerification if the user is DSA
          if (isDSA) AccountVerification(username: widget.username),
          AccountPage(username: widget.username),
          // Only add StudentsPage if the user is DSA
          if (isDSA) StudentsPage(username: widget.username),
        ]);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade600,
        elevation: 0,
        title: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('admin')
              .doc(widget.username)
              .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }

            if (snapshot.hasError) {
              return const Text("Error loading admin data");
            }

            if (snapshot.hasData && snapshot.data != null) {
              var adminData = snapshot.data!.data() as Map<String, dynamic>;
              String adminName = adminData['name'] ?? 'Admin';
              return Text(
                'AppDate - $adminName',
                style: const TextStyle(color: Colors.white),
              );
            } else {
              return const Text(
                'AppDate',
                style: TextStyle(color: Colors.white),
              );
            }
          },
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Background Image with transparency
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: Image.asset(
                'assets/logo_ndmu.png',
                alignment: Alignment.center,
              ),
            ),
          ),
          // Main Content
          Row(
            children: [
              // Left-side navigation panel
              Container(
                width: 200,
                color: Colors.grey.shade200.withOpacity(0.9),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Traditional clickable text items for navigation
                    // Traditional clickable text items for navigation
                    _buildNavButton("Posts", 0),
                    if (isDSA) _buildNavButton("Creators", 1),
                    if (isDSA) _buildNavButton("Students", 3),
                    const Spacer(),
                    _buildNavButton("Account", isDSA ? 2 : 1),
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
                  child: _pages.isNotEmpty
                      ? _pages[_selectedIndex]
                      : Center(child: CircularProgressIndicator()),
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Get the admin name from Firestore
          DocumentSnapshot adminSnapshot = await FirebaseFirestore.instance
              .collection('admin')
              .doc(widget.username)
              .get();

          if (adminSnapshot.exists) {
            var adminData = adminSnapshot.data() as Map<String, dynamic>;
            String adminName = adminData['name'] ?? 'Admin';

            await CalendarPage.showEventDialog(context, adminName);
          }
        },
        backgroundColor: Colors.green.shade600,
        child: const Icon(Icons.calendar_month_rounded),
      ),
    );
  }

  // Custom method to build navigation buttons with borders and rounded corners
  Widget _buildNavButton(String label, int index) {
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: _selectedIndex == index
              ? Colors.green.shade600
              : Colors.transparent,
          border: Border.all(
            color: _selectedIndex == index
                ? Colors.green.shade600
                : Colors.grey.shade400,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: _selectedIndex == index ? Colors.white : Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StudentsPage extends StatelessWidget {
  final String username;

  const StudentsPage({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // Background widget (if you have a background to preserve)
              Positioned.fill(
                child: Container(
                  color: Colors.grey[200], // Example background color
                ),
              ),

              // Table positioned at the top
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0), // Add some top padding
                    child: Text(
                      'Students List',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Expanded(
                    child: FutureBuilder(
                      future: _fetchStudents(username),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError) {
                          return Center(
                              child: Text('Error: ${snapshot.error}'));
                        }

                        List<Map<String, dynamic>> students = snapshot.data!;
                        return SingleChildScrollView(
                          scrollDirection:
                              Axis.horizontal, // Enable horizontal scrolling
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: constraints
                                  .maxWidth, // Stretch table to fit screen width
                            ),
                            child: DataTable(
                              columnSpacing:
                                  20.0, // Adjust spacing between columns
                              headingRowHeight: 48.0,
                              dataRowHeight: 56.0,
                              columns: const [
                                DataColumn(
                                    label: Expanded(child: Text('First Name'))),
                                DataColumn(
                                    label: Expanded(child: Text('Last Name'))),
                                DataColumn(
                                    label: Expanded(child: Text('Email'))),
                                DataColumn(
                                    label: Expanded(child: Text('School ID'))),
                              ],
                              rows: students.map((student) {
                                return DataRow(
                                  cells: [
                                    DataCell(
                                        Text(student['firstName'] ?? 'N/A')),
                                    DataCell(
                                        Text(student['lastName'] ?? 'N/A')),
                                    DataCell(Text(student['email'] ?? 'N/A')),
                                    DataCell(
                                        Text(student['schoolId'] ?? 'N/A')),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  // Function to fetch students from Firestore
  Future<List<Map<String, dynamic>>> _fetchStudents(String username) async {
    QuerySnapshot snapshot;

    if (_isAdmin(username)) {
      // Fetch all students for admin roles
      snapshot = await FirebaseFirestore.instance.collection('Users').get();
    } else {
      // Fetch students based on the department for DEAN roles
      String department = username.replaceAll('_DEAN', ''); // Remove '_DEAN'
      snapshot = await FirebaseFirestore.instance
          .collection('Users')
          .where('department', isEqualTo: department)
          .get();
    }

    // Filter out creators programmatically (UIDs starting with 'c')
    return snapshot.docs
        .where((doc) => !doc.id.startsWith('c')) // Exclude creators
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();
  }

  // Helper method to check if the username belongs to a specific admin role
  bool _isAdmin(String username) {
    const adminUsernames = ['DSA', 'ACAD_VP', 'QUAPS', 'VP_ADMIN'];
    return adminUsernames.contains(username);
  }
}

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Import the http package

class AccountVerification extends StatefulWidget {
  final String username;

  const AccountVerification({super.key, required this.username});

  @override
  State<AccountVerification> createState() => _AccountVerificationState();
}

class _AccountVerificationState extends State<AccountVerification> {
  late Future<List<QueryDocumentSnapshot>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _fetchUsers(); // Initial fetch
  }

  Future<void> sendEmailConfirmation(
      String email, String clubID, String clubName, String password) async {
    const String serviceId = 'service_znustkk';
    const String templateId = 'template_9db3awh';
    const String userId = '8FjUfae60Qdd0PMxc';

    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
    final payload = {
      'service_id': serviceId,
      'template_id': templateId,
      'user_id': userId,
      'template_params': {
        'email': email,
        'clubID': clubID,
        'clubName': clubName,
        'password': password,
      },
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        debugPrint('Email sent successfully!');
      } else {
        debugPrint(
            'Failed to send email. Status code: ${response.statusCode}. Response body: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error sending email: $e');
    }
  }

  Future<void> _fetchUsers() async {
    bool isDean = widget.username.endsWith('_DEAN');
    String department = isDean ? widget.username.split('_')[0] : '';

    try {
      _usersFuture = FirebaseFirestore.instance
          .collection('Users')
          .where('department', isEqualTo: isDean ? department : null)
          .get()
          .then((snapshot) => snapshot.docs);
      setState(() {});
    } catch (e) {
      debugPrint('Error fetching users: $e');
    }
  }

  Future<void> updateApprovalStatus(String uid, String newStatus) async {
    try {
      // Fetch the user's document
      var userDoc =
          await FirebaseFirestore.instance.collection('Users').doc(uid).get();

      if (userDoc.exists) {
        String userDepartment = userDoc['department'] ?? 'N/A';

        // Allow only DSA admin to approve/reject "Non Academic" creators
        if (userDepartment == "Non Academic" && widget.username != "DSA") {
          debugPrint(
              'Only the DSA admin can approve/reject creators from the "Non Academic" department.');
          return;
        }

        // Proceed with updating the approval status
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(uid)
            .update({'approvalStatus': newStatus});

        String userEmail = userDoc['email'] ?? '';
        String clubID = userDoc['clubID'] ?? 'N/A';
        String clubName = userDoc['clubName'] ?? 'N/A';
        String password = userDoc['password'] ?? 'N/A';

        if (newStatus == 'accepted') {
          try {
            await sendEmailConfirmation(userEmail, clubID, clubName, password);
          } catch (e) {
            debugPrint('Error occurred while sending email: $e');
          }
        }

        _fetchUsers(); // Refresh user data after updating
      }
    } catch (e) {
      debugPrint('Error updating approval status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDean = widget.username.endsWith('_DEAN');
    String department = isDean ? widget.username.split('_')[0] : '';

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: FutureBuilder<List<QueryDocumentSnapshot>>(
              future: _usersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No users to verify.'));
                }

                var users = snapshot.data!;

                // Filter to include only creators (UID starts with 'c')
                var creators =
                    users.where((user) => user.id.startsWith('c')).toList();

                // Sort creators based on approvalStatus: pending > accepted > rejected
                creators.sort((a, b) {
                  String statusA = a['approvalStatus'] ?? 'pending';
                  String statusB = b['approvalStatus'] ?? 'pending';
                  int statusOrder(String status) {
                    switch (status) {
                      case 'pending':
                        return 0;
                      case 'accepted':
                        return 1;
                      case 'rejected':
                        return 2;
                      default:
                        return 3;
                    }
                  }

                  return statusOrder(statusA).compareTo(statusOrder(statusB));
                });

                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: constraints.maxWidth,
                        maxHeight: constraints.maxHeight,
                      ),
                      child: DataTable(
                        columnSpacing: 20,
                        headingRowHeight: 40,
                        dataRowHeight: 56,
                        columns: const [
                          DataColumn(label: Text('UID')),
                          DataColumn(label: Text('Name')),
                          DataColumn(label: Text('Email')),
                          DataColumn(label: Text('Department')),
                          DataColumn(label: Text('Approval Status')),
                        ],
                        rows: creators.map((user) {
                          String uid = user.id;
                          String userName = user['clubName'] ?? 'N/A';
                          String userEmail = user['email'] ?? 'N/A';
                          String userDepartment = user['department'] ?? 'N/A';
                          String approvalStatus =
                              user['approvalStatus'] ?? 'pending';

                          Color statusColor = Colors.orange;
                          if (approvalStatus == 'accepted')
                            statusColor = Colors.green;
                          if (approvalStatus == 'rejected')
                            statusColor = Colors.red;

                          return DataRow(
                            cells: [
                              DataCell(Text(uid)),
                              DataCell(Text(userName)),
                              DataCell(Text(userEmail)),
                              DataCell(Text(userDepartment)),
                              DataCell(
                                isDean && userDepartment == department ||
                                        (userDepartment == "Non Academic" &&
                                            widget.username == "DSA")
                                    ? approvalStatus == 'pending'
                                        ? Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.check,
                                                    color: Colors.green),
                                                onPressed: () =>
                                                    updateApprovalStatus(
                                                        uid, 'accepted'),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.close,
                                                    color: Colors.red),
                                                onPressed: () =>
                                                    updateApprovalStatus(
                                                        uid, 'rejected'),
                                              ),
                                            ],
                                          )
                                        : Text(
                                            approvalStatus,
                                            style:
                                                TextStyle(color: statusColor),
                                          )
                                    : Text(
                                        approvalStatus,
                                        style: TextStyle(color: statusColor),
                                      ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

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

    debugPrint('Preparing to send email...');
    debugPrint('Payload: $payload');

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
    debugPrint('Fetching users for verification...');
    bool isDean = widget.username.endsWith('_DEAN');
    String department = isDean ? widget.username.split('_')[0] : '';

    try {
      _usersFuture = FirebaseFirestore.instance
          .collection('Users')
          .where('department', isEqualTo: isDean ? department : null)
          .get()
          .then((snapshot) {
        debugPrint(
            'Fetched ${snapshot.docs.length} users for department: $department');
        return snapshot.docs;
      });
      setState(() {});
    } catch (e) {
      debugPrint('Error fetching users: $e');
    }
  }

  Future<void> updateApprovalStatus(String uid, String newStatus) async {
    try {
      debugPrint('Updating approval status for UID: $uid to $newStatus');
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(uid)
          .update({'approvalStatus': newStatus});
      debugPrint('Approval status updated successfully for UID: $uid');

      // Fetch user details for email notification
      var userDoc =
          await FirebaseFirestore.instance.collection('Users').doc(uid).get();

      if (userDoc.exists) {
        debugPrint('Fetched user details for UID: $uid');
        String userEmail = userDoc['email'] ?? '';
        String clubID = userDoc['clubID'] ?? 'N/A';
        String clubName = userDoc['clubName'] ?? 'N/A';
        String password = userDoc['password'] ?? 'N/A';

        // Send email if account is accepted
        if (newStatus == 'accepted') {
          try {
            debugPrint(
                'Sending email confirmation to $userEmail with clubID: $clubID and clubName: $clubName');
            await sendEmailConfirmation(userEmail, clubID, clubName, password);
            debugPrint('Email confirmation sent successfully for UID: $uid');
          } catch (e) {
            debugPrint(
                'Error occurred while sending email for UID: $uid. Error: $e');
          }
        }
      } else {
        debugPrint('User document does not exist for UID: $uid');
      }

      _fetchUsers(); // Refresh user data after updating
    } catch (e) {
      debugPrint('Error updating approval status for UID: $uid. Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDean = widget.username.endsWith('_DEAN');
    String department = isDean ? widget.username.split('_')[0] : '';

    return FutureBuilder<List<QueryDocumentSnapshot>>(
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

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // Align to top
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 8.0),
                child: Text(
                  'Account Verification',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('UID')),
                      DataColumn(label: Text('Name')),
                      DataColumn(label: Text('Email')),
                      DataColumn(label: Text('Department')),
                      DataColumn(label: Text('Approval Status')),
                    ],
                    rows: users.map((user) {
                      String uid = user.id;

                      // Check UID type: creator starts with 'c', student is numeric
                      bool isCreator = uid.startsWith('c');
                      String userName = isCreator
                          ? user['clubName'] ?? 'N/A'
                          : '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}';
                      String userEmail = user['email'] ?? 'N/A';
                      String userDepartment = user['department'] ?? 'N/A';
                      String approvalStatus = isCreator
                          ? (user['approvalStatus'] ?? 'pending')
                          : 'N/A';

                      // Define status color (only for creators)
                      Color statusColor = Colors.orange; // Default to pending
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
                            isCreator
                                ? isDean && userDepartment == department
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
                                      )
                                : const Text('N/A'),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

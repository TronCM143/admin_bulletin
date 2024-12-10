import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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

  Future<void> _fetchUsers() async {
    bool isDean = widget.username.endsWith('_DEAN');
    String department = isDean ? widget.username.split('_')[0] : '';

    // Fetch users based on role
    _usersFuture = FirebaseFirestore.instance
        .collection('Users')
        .where('department', isEqualTo: isDean ? department : null)
        .get()
        .then((snapshot) => snapshot.docs);
    setState(() {}); // Triggers UI rebuild after fetching data
  }

  Future<void> updateApprovalStatus(String uid, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(uid)
          .update({'approvalStatus': newStatus});
      _fetchUsers(); // Refresh user data after updating
    } catch (e) {
      debugPrint('Error updating approval status: $e');
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

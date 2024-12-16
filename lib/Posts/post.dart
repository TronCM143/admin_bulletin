import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

class Posts extends StatefulWidget {
  final String username;

  const Posts({Key? key, required this.username}) : super(key: key);

  @override
  _PostsState createState() => _PostsState();
}

class _PostsState extends State<Posts> {
  List<QueryDocumentSnapshot> allPosts = [];
  bool isLoading = true;
  Map<String, String> postStatusMap = {};

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  /// Method to update the expiry date of the post
  Future<void> _updateExpiryDate(String postId, DateTime newExpiryDate) async {
    try {
      await FirebaseFirestore.instance
          .collection('Posts')
          .doc(postId)
          .update({'expirationDate': newExpiryDate});
      setState(() {
        // Optionally refresh the posts after updating the expiry date
      });
    } catch (e) {
      print('Error updating expiry date: $e');
    }
  }

  Future<void> _fetchPosts() async {
    try {
      allPosts = await _fetchPostsFromFirestore(widget.username);
      setState(() {
        isLoading = false;
      });

      for (var post in allPosts) {
        final status =
            await _fetchPostStatusFromFirestore(widget.username, post.id);
        if (status != null) {
          setState(() {
            postStatusMap[post.id] = status;
          });
        }
      }

      _sortPostsByStatus();
    } catch (error) {
      print('Error fetching posts: $error');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<List<QueryDocumentSnapshot>> _fetchPostsFromFirestore(
      String username) async {
    List<QueryDocumentSnapshot> relevantPosts = [];

    try {
      // Fetch all posts from Firestore
      QuerySnapshot postsSnapshot =
          await FirebaseFirestore.instance.collection('Posts').get();

      for (var post in postsSnapshot.docs) {
        final postId = post.id;

        // Fetch the 'approvals' subcollection for this post
        QuerySnapshot approvalsSnapshot = await FirebaseFirestore.instance
            .collection('Posts')
            .doc(postId)
            .collection('approvals')
            .get();

        // Filter and sort approvals relevant to the hierarchy
        final approvals = approvalsSnapshot.docs.map((doc) {
          return {
            'username': doc.id,
            'status': doc['status'],
            'order':
                getHierarchyOrder(doc.id), // Use helper to get hierarchy order
          };
        }).toList();

        // Ensure approvals are sorted by hierarchy order
        approvals.sort((a, b) => a['order']!.compareTo(b['order']!));

        // Check if this post involves the given username
        final userApprovalIndex = approvals
            .indexWhere((approval) => approval['username'] == username);

        if (userApprovalIndex == -1) {
          // Skip posts where username is not part of the approval hierarchy
          continue;
        }

        // Validate the hierarchy rules
        if (userApprovalIndex > 0 &&
            approvals[userApprovalIndex - 1]['status'] == 'pending') {
          print(
              "Post $postId: Cannot approve because the previous node '${approvals[userApprovalIndex - 1]['username']}' is still pending.");
          continue;
        }

        // Fetch the current status of this user's approval
        final currentStatus = approvals[userApprovalIndex]['status'];

        if (currentStatus == 'pending') {
          // Allow the user to approve or reject the post
          print("Post $postId: User $username can update the status.");
          relevantPosts.add(post);
        } else {
          // Include posts that are already approved or rejected
          relevantPosts.add(post);
          print(
              "Post $postId: Already ${currentStatus}, included in the list.");
        }
      }
    } catch (e) {
      print('Error processing approvals for username $username: $e');
    }

    return relevantPosts;
  }

  // Helper to get the hierarchy order
  int getHierarchyOrder(String username) {
    const hierarchy = [
      'MOD_Kariktan',
      'MOD_Kutitap Theatre',
      'MOD_PSITS',
      'MOD_BLIS',
      'MOD_PICE',
      'MOD_CSD',
      'MOD_SEAS',
      'MOD_SSG',
      'CEAC_DEAN',
      'CAS_DEAN',
      'CBA_DEAN',
      'CED_DEAN',
      'QUAPS',
      'DSA',
      'ACAD_VP',
      'VP_ADMIN'
    ];

    final order = hierarchy.indexOf(username);

    if (order == -1) {
      print("Warning: Username '$username' not found in hierarchy.");
    }

    return order;
  }

  Future<String?> _fetchPostStatusFromFirestore(
      String username, String postId) async {
    try {
      final approvalDoc = await FirebaseFirestore.instance
          .collection('Posts')
          .doc(postId)
          .collection('approvals')
          .doc(username)
          .get();

      return approvalDoc.exists ? approvalDoc['status'] as String? : null;
    } catch (e) {
      print('Error fetching post status: $e');
      return null;
    }
  }

  Future<void> _updatePostStatus(String postId, String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('Posts')
          .doc(postId)
          .collection('approvals')
          .doc(widget.username)
          .update({'status': status});
      setState(() {
        postStatusMap[postId] = status;
      });
      _fetchPosts(); // Refresh posts after updating the status
    } catch (error) {
      print('Error updating post status: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $error')),
      );
    }
  }

  void _sortPostsByStatus() {
    setState(() {
      allPosts.sort((a, b) {
        String statusA = postStatusMap[a.id] ?? 'pending';
        String statusB = postStatusMap[b.id] ?? 'pending';

        if (statusA == 'pending' && statusB != 'pending') return -1;
        if (statusA == 'accepted' && statusB == 'rejected') return -1;
        if (statusA == 'rejected' && statusB != 'rejected') return 1;
        if (statusB == 'pending' && statusA != 'pending') return 1;
        if (statusB == 'accepted' && statusA == 'rejected') return 1;

        return 0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/logo_ndmu.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100]?.withOpacity(0.9),
          ),
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Expanded(
                      child: allPosts.isEmpty
                          ? const Center(
                              child: Text(
                                'No posts available',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          : _buildPostTable(context),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildPostTable(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints:
            BoxConstraints(minWidth: MediaQuery.of(context).size.width),
        child: DataTable(
          headingRowColor:
              MaterialStateProperty.all(Colors.blueAccent.withOpacity(0.1)),
          dataRowColor: MaterialStateProperty.resolveWith<Color?>(
            (Set<MaterialState> states) {
              if (states.contains(MaterialState.selected)) {
                return Colors.grey.withOpacity(0.2);
              }
              return Colors.transparent;
            },
          ),
          dataRowHeight: 70,
          columns: const [
            DataColumn(
                label: Text('Time',
                    style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(
                label: Text('Name',
                    style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(
                label: Text('Title',
                    style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(
                label: Text('Content',
                    style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(
                label: Text('Attachments',
                    style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(
                label: Text('Set Post Expiry (DSA)',
                    style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(
                label: Text('Status',
                    style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: allPosts.map((post) {
            final postData = post.data() as Map<String, dynamic>;
            final title = postData['title'] ?? 'No Title';
            final postId = post.id;
            final content = postData['content'] ?? 'No content available';
            final imageUrls = postData['imageUrls'] ?? [];
            final timestamp = postData['timestamp'] as Timestamp;
            final postTime = timestamp.toDate();
            final name = postData['creatorName'] ?? 'No Name';
            final formattedTime =
                DateFormat('MMM dd, yyyy HH:mm').format(postTime);
            final status = postStatusMap[postId] ?? 'pending';
            final postExpiry =
                postData['expirationDate']?.toDate() ?? DateTime.now();

            return DataRow(cells: [
              DataCell(Text(formattedTime)),
              DataCell(Text(name)),
              DataCell(
                GestureDetector(
                  onTap: () => _showFullTextDialog(context, title, 'Title'),
                  child: Container(
                    width: 200,
                    child: Text(
                      title,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
              DataCell(
                GestureDetector(
                  onTap: () => _showFullTextDialog(context, content, 'Content'),
                  child: Container(
                    width: 200,
                    child: Text(
                      content,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
              DataCell(_buildAttachments(imageUrls)),
              // Add the "Post Expiry" cell conditionally
              DataCell(
                ElevatedButton.icon(
                  onPressed: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: postExpiry,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101),
                    );

                    if (pickedDate != null && pickedDate != postExpiry) {
                      _updateExpiryDate(postId, pickedDate);
                    }
                  },
                  icon: Icon(Icons.calendar_today,
                      color: Colors.white), // Calendar icon
                  label: const Text(
                    'Set Date',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green // No shadow
                      ),
                ),
              ),
              DataCell(Row(
                children: [
                  Text(status),
                  if (status == 'pending') ...[
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () {
                        _updatePostStatus(postId, 'accepted');
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () {
                        _updatePostStatus(postId, 'rejected');
                      },
                    ),
                  ],
                ],
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }

// Method to show the full content in a dialog
  void _showFullTextDialog(BuildContext context, String text, String type) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            type,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Container(
            width: 500, // Set the fixed width here
            child: SingleChildScrollView(
              child: Text(text),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttachments(List<dynamic> imageUrls) {
    if (imageUrls.isEmpty) {
      return const Text('No attachments');
    }
    return Row(
      children: imageUrls.map((imageUrl) {
        return Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            placeholder: (context, url) => const CircularProgressIndicator(),
            errorWidget: (context, url, error) => const Icon(Icons.error),
            width: 50,
            height: 50,
            fit: BoxFit.cover,
          ),
        );
      }).toList(),
    );
  }
}

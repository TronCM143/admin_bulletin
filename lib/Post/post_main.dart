import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Post extends StatelessWidget {
  final String username;

  const Post({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    return PostManager(username: username);
  }
}

class PostManager extends StatefulWidget {
  final String username;

  const PostManager({super.key, required this.username});

  @override
  _PostManagerState createState() => _PostManagerState();
}

class _PostManagerState extends State<PostManager> {
  List<QueryDocumentSnapshot> allPosts = [];
  bool isLoading = true;
  Map<String, String> postStatusMap = {}; // Store post statuses here

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  Future<void> _fetchPosts() async {
    try {
      QuerySnapshot snapshot;
      String department = _getDepartmentFromUsername(widget.username);

      if (department != 'default') {
        snapshot = await FirebaseFirestore.instance
            .collection('Posts')
            .where('department', isEqualTo: department)
            .get();
      } else {
        snapshot = await FirebaseFirestore.instance.collection('Posts').get();
      }

      setState(() {
        allPosts = snapshot.docs;
        isLoading = false;
      });

      // Fetch post statuses and store them
      for (var post in allPosts) {
        await _fetchPostStatus(post.id);
      }

      // Sort the posts based on status
      _sortPostsByStatus();
    } catch (error) {
      print('Error fetching posts: $error');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchPostStatus(String postId) async {
    try {
      final approvalDoc = await FirebaseFirestore.instance
          .collection('Posts')
          .doc(postId)
          .collection('approvals')
          .doc(widget.username)
          .get();

      if (approvalDoc.exists) {
        setState(() {
          postStatusMap[postId] = approvalDoc['status'] ?? 'pending';
        });
      }
    } catch (error) {
      print('Error fetching post status: $error');
    }
  }

  void _sortPostsByStatus() {
    setState(() {
      allPosts.sort((a, b) {
        String statusA = postStatusMap[a.id] ?? 'pending';
        String statusB = postStatusMap[b.id] ?? 'pending';

        // Priority order: 'pending' > 'accepted' > 'rejected'
        if (statusA == 'pending' && statusB != 'pending') return -1;
        if (statusA == 'accepted' && statusB == 'rejected') return -1;
        if (statusA == 'rejected' && statusB != 'rejected') return 1;
        if (statusB == 'pending' && statusA != 'pending') return 1;
        if (statusB == 'accepted' && statusA == 'rejected') return 1;

        return 0; // Default if statuses are the same
      });
    });
  }

  String _getDepartmentFromUsername(String username) {
    if (username.endsWith('_DEAN')) {
      return username.split('_')[0];
    } else if (['ACAD_VP', 'ADMIN_VP', 'DSA', 'QUAPS'].contains(username)) {
      return 'default';
    }
    return 'default';
  }

  Future<void> _updatePostStatus(String postId, String status) async {
    try {
      // Update the status in Firestore
      await FirebaseFirestore.instance
          .collection('Posts')
          .doc(postId)
          .collection('approvals')
          .doc(widget.username)
          .update({'status': status});

      // Update the local status in the map and UI
      setState(() {
        postStatusMap[postId] = status;
      });

      // Re-sort posts based on updated status
      _sortPostsByStatus();
    } catch (error) {
      print('Error updating post status: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : allPosts.isEmpty
            ? const Center(child: Text('No posts available'))
            : SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SizedBox(
                  width: double.infinity,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Time')),
                      DataColumn(label: Text('Club Name')),
                      DataColumn(label: Text('Content')),
                      DataColumn(label: Text('Attachments')),
                      DataColumn(label: Text('Status')),
                    ],
                    rows: allPosts.map((post) {
                      final postData = post.data() as Map<String, dynamic>;
                      final postId = post.id;
                      final content =
                          postData['content'] ?? 'No content available';
                      final truncatedContent = content.length > 30
                          ? '${content.substring(0, 30)}...'
                          : content;
                      final imageUrls = postData['imageUrls'] ?? [];

                      String status = postStatusMap[postId] ?? 'pending';
                      Color statusColor = Colors.orange;
                      if (status == 'accepted') statusColor = Colors.green;
                      if (status == 'rejected') statusColor = Colors.red;

                      return DataRow(cells: [
                        DataCell(Text(postData['time'] ?? 'N/A')),
                        DataCell(Text(postData['clubName'] ?? 'Unknown')),
                        DataCell(Text(truncatedContent)),
                        DataCell(
                          Wrap(
                            spacing: 8.0,
                            children: imageUrls.map<Widget>((imageUrl) {
                              return GestureDetector(
                                onTap: () {
                                  _showImagePreview(context, imageUrl);
                                },
                                child: CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) =>
                                      const CircularProgressIndicator(),
                                  errorWidget: (context, url, error) =>
                                      const Icon(Icons.error),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        DataCell(
                          status == 'pending'
                              ? Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.check,
                                          color: Colors.green),
                                      onPressed: () =>
                                          _updatePostStatus(postId, 'accepted'),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close,
                                          color: Colors.red),
                                      onPressed: () =>
                                          _updatePostStatus(postId, 'rejected'),
                                    ),
                                  ],
                                )
                              : Text(
                                  status,
                                  style: TextStyle(color: statusColor),
                                ),
                        ),
                      ]);
                    }).toList(),
                  ),
                ),
              );
  }

  void _showImagePreview(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: FractionallySizedBox(
            alignment: Alignment.center,
            widthFactor: 0.6, // Adjust the width as needed
            heightFactor: 0.6, // Adjust the height as needed
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit:
                  BoxFit.contain, // Ensure the image maintains its aspect ratio
              placeholder: (context, url) =>
                  const Center(child: CircularProgressIndicator()),
              errorWidget: (context, url, error) =>
                  const Center(child: Icon(Icons.error)),
            ),
          ),
        );
      },
    );
  }
}

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

  Future<void> _fetchPosts() async {
    try {
      allPosts = await _fetchPostsFromFirestore(widget.username);
      setState(() {
        isLoading = false;
      });

      for (var post in allPosts) {
        final status =
            await _fetchPostStatusFromFirestore(widget.username, post.id);
        setState(() {
          postStatusMap[post.id] = status ?? 'pending';
        });
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
    String department = _getDepartmentFromUsername(username);
    QuerySnapshot snapshot;

    if (department != 'default') {
      snapshot = await FirebaseFirestore.instance
          .collection('Posts')
          .where('department', isEqualTo: department)
          .get();
    } else {
      snapshot = await FirebaseFirestore.instance.collection('Posts').get();
    }

    return snapshot.docs;
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
      _sortPostsByStatus();
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

  String _getDepartmentFromUsername(String username) {
    if (username.endsWith('_DEAN')) {
      return username.split('_')[0];
    } else if (['ACAD_VP', 'ADMIN_VP', 'DSA', 'QUAPS'].contains(username)) {
      return 'default';
    }
    return 'default';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/logo.ndmu.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 16.0, bottom: 8.0),
                    child: Text(
                      'Posts',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    child: allPosts.isEmpty
                        ? const Center(child: Text('No posts available'))
                        : _buildPostTable(),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildPostTable() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(Colors.transparent),
              dataRowColor: MaterialStateProperty.resolveWith<Color?>(
                (Set<MaterialState> states) {
                  if (states.contains(MaterialState.selected)) {
                    return Colors.grey.withOpacity(0.2);
                  }
                  return Colors.transparent;
                },
              ),
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
                final content = postData['content'] ?? 'No content available';
                final imageUrls = postData['imageUrls'] ?? [];
                final timestamp = postData['timestamp'] as Timestamp;
                final postTime = timestamp.toDate();
                final formattedTime =
                    DateFormat('MMM dd, yyyy HH:mm').format(postTime);
                final status = postStatusMap[postId] ?? 'pending';
                final statusColor = status == 'accepted'
                    ? Colors.green
                    : (status == 'rejected' ? Colors.red : Colors.orange);

                return DataRow(cells: [
                  DataCell(Text(formattedTime)),
                  DataCell(Text(postData['clubName'] ?? 'Unknown')),
                  DataCell(
                    ConstrainedBox(
                      constraints:
                          BoxConstraints(maxWidth: constraints.maxWidth * 0.2),
                      child: Text(
                        content,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataCell(
                    ConstrainedBox(
                      constraints:
                          BoxConstraints(maxWidth: constraints.maxWidth * 0.2),
                      child: Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
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
                                icon:
                                    const Icon(Icons.close, color: Colors.red),
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
      },
    );
  }

  void _showImagePreview(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: FractionallySizedBox(
            alignment: Alignment.center,
            widthFactor: 0.6,
            heightFactor: 0.6,
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.contain,
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

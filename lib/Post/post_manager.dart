import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'post_services.dart';
import 'post_table.dart';

class PostManager extends StatefulWidget {
  final String username;

  const PostManager({super.key, required this.username});

  @override
  _PostManagerState createState() => _PostManagerState();
}

class _PostManagerState extends State<PostManager> {
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
      allPosts = await PostService.fetchPosts(widget.username);
      setState(() {
        isLoading = false;
      });

      // Fetch and sort post statuses
      for (var post in allPosts) {
        final status =
            await PostService.fetchPostStatus(widget.username, post.id);
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

  Future<void> _updatePostStatus(String postId, String status) async {
    try {
      await PostService.updatePostStatus(widget.username, postId, status);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: allPosts.isEmpty
                      ? const Center(child: Text('No posts available'))
                      : PostTable(
                          allPosts: allPosts,
                          postStatusMap: postStatusMap,
                          onUpdateStatus: _updatePostStatus,
                        ),
                ),
              ],
            ),
    );
  }
}

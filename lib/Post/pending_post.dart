import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'post_loader.dart';
import 'updatePostStatus.dart';

class PendingPosts extends StatefulWidget {
  final String username;

  const PendingPosts({super.key, required this.username});

  @override
  _PendingPostsState createState() => _PendingPostsState();
}

class _PendingPostsState extends State<PendingPosts> {
  List<QueryDocumentSnapshot> filteredDocuments = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFilteredPosts();
  }

  void _loadFilteredPosts() {
    PostLoader.loadFilteredPosts(
      adminUsername: widget.username,
      onPostsLoaded: (List<QueryDocumentSnapshot> posts) {
        setState(() {
          filteredDocuments = posts;
        });
      },
      onLoadingComplete: () {
        setState(() {
          isLoading = false;
        });
      },
      onError: () {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error loading pending posts')));
      },
    );
  }

  void _handlePostStatusUpdate(String postId, String status) {
    PostStatusUpdater.updatePostStatus(
      context: context,
      postId: postId,
      status: status,
      adminUsername: widget.username,
      onPostRemoved: (postId) {
        setState(() {
          filteredDocuments.removeWhere((doc) => doc.id == postId);
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : filteredDocuments.isEmpty
            ? const Center(child: Text('No pending posts.'))
            : Column(
                children: [
                  // Header Row
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    color: Colors.green[100],
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Timestamp',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Club Name',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Title',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: Text(
                            'Content',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Attachments',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        SizedBox(width: 50), // Space for Approve/Reject buttons
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: filteredDocuments.length,
                      itemBuilder: (context, index) {
                        var document = filteredDocuments[index];
                        var data = document.data() as Map<String, dynamic>;

                        String formattedTime = DateFormat('yyyy-MM-dd HH:mm')
                            .format((data['timestamp'] as Timestamp).toDate());

                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Post Details
                              Expanded(
                                flex: 12,
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        formattedTime,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        data['clubName'] ?? 'N/A',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        data['title'] ?? 'No Title',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 4,
                                      child: Text(
                                        data['content'] ?? 'No Content',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Row(
                                        children: (data['imageUrls'] != null &&
                                                (data['imageUrls'] as List)
                                                    .isNotEmpty)
                                            ? (data['imageUrls'] as List)
                                                .map<Widget>((imageUrl) {
                                                return GestureDetector(
                                                  onTap: () {
                                                    showDialog(
                                                      context: context,
                                                      builder: (context) {
                                                        return Dialog(
                                                          child:
                                                              CachedNetworkImage(
                                                            imageUrl: imageUrl,
                                                            fit: BoxFit.cover,
                                                            placeholder: (context,
                                                                    url) =>
                                                                const CircularProgressIndicator(),
                                                            errorWidget: (context,
                                                                    url,
                                                                    error) =>
                                                                const Icon(Icons
                                                                    .error),
                                                          ),
                                                        );
                                                      },
                                                    );
                                                  },
                                                  child: CachedNetworkImage(
                                                    imageUrl: imageUrl,
                                                    width: 30,
                                                    height: 30,
                                                    fit: BoxFit.cover,
                                                    placeholder: (context,
                                                            url) =>
                                                        const CircularProgressIndicator(),
                                                    errorWidget: (context, url,
                                                            error) =>
                                                        const Icon(Icons.error),
                                                  ),
                                                );
                                              }).toList()
                                            : [
                                                const Icon(
                                                  Icons.image_not_supported,
                                                  size: 30,
                                                  color: Colors.grey,
                                                )
                                              ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Approve/Reject Buttons
                              Column(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.check,
                                        color: Colors.green),
                                    onPressed: () => _handlePostStatusUpdate(
                                        document.id, 'accepted'),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close,
                                        color: Colors.red),
                                    onPressed: () => _handlePostStatusUpdate(
                                        document.id, 'rejected'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
  }
}

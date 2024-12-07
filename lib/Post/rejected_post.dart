import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RejectedPost extends StatefulWidget {
  final String username;

  const RejectedPost({super.key, required this.username});

  @override
  _RejectedPostState createState() => _RejectedPostState();
}

class _RejectedPostState extends State<RejectedPost> {
  List<QueryDocumentSnapshot> acceptedDocuments = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRejectedPost();
  }

  void _loadRejectedPost() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('Posts').get();

      List<QueryDocumentSnapshot> tempRejectedPost = [];

      for (var document in snapshot.docs) {
        DocumentReference postRef = document.reference;

        // Fetch the "approvals" sub-collection for this post
        DocumentSnapshot adminApprovalDoc =
            await postRef.collection('approvals').doc(widget.username).get();

        // Check if the post has been accepted by this admin
        if (adminApprovalDoc.exists &&
            adminApprovalDoc['status'] == 'rejected') {
          tempRejectedPost.add(document);
        }
      }

      setState(() {
        acceptedDocuments = tempRejectedPost;
        isLoading = false;
      });
    } catch (error) {
      print('Error loading accepted posts: $error');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : acceptedDocuments.isEmpty
            ? const Center(child: Text('No accepted posts.'))
            : Column(
                children: [
                  // Column headers
                  Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    color: Colors.green[100],
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Timestamp',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Club Name',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Title',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: Text(
                            'Content',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Attachments',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: acceptedDocuments.length,
                      itemBuilder: (context, index) {
                        var document = acceptedDocuments[index];
                        var data = document.data() as Map<String, dynamic>;

                        String formattedTime = DateFormat('yyyy-MM-dd HH:mm')
                            .format((data['timestamp'] as Timestamp).toDate());

                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.green[50],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Timestamp
                              Expanded(
                                flex: 2,
                                child: Text(
                                  formattedTime,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              // Club Name
                              Expanded(
                                flex: 2,
                                child: Text(
                                  data['clubName'] ?? 'N/A',
                                  style: const TextStyle(
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              // Title
                              Expanded(
                                flex: 2,
                                child: Text(
                                  data['title'] ?? 'No Title',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              // Content
                              Expanded(
                                flex: 4,
                                child: Text(
                                  data['content'] ?? 'No Content',
                                  style: const TextStyle(
                                    fontSize: 14,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // Images
                              Expanded(
                                flex: 2,
                                child: Row(
                                  children: (data['imageUrls'] != null &&
                                          (data['imageUrls'] as List)
                                              .isNotEmpty)
                                      ? (data['imageUrls'] as List)
                                          .map<Widget>((imageUrl) {
                                          return Padding(
                                            padding:
                                                const EdgeInsets.only(right: 4),
                                            child: GestureDetector(
                                              onTap: () {
                                                showDialog(
                                                  context: context,
                                                  builder: (context) {
                                                    return Dialog(
                                                      child: CachedNetworkImage(
                                                        imageUrl: imageUrl,
                                                        fit: BoxFit.cover,
                                                        placeholder: (context,
                                                                url) =>
                                                            const Center(
                                                                child:
                                                                    CircularProgressIndicator()),
                                                        errorWidget: (context,
                                                                url, error) =>
                                                            const Center(
                                                                child: Icon(Icons
                                                                    .error)),
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
                                                placeholder: (context, url) =>
                                                    const CircularProgressIndicator(),
                                                errorWidget:
                                                    (context, url, error) =>
                                                        const Icon(Icons.error),
                                              ),
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
                        );
                      },
                    ),
                  ),
                ],
              );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RequestsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collectionGroup('posts').snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No requests available.'));
        }

        final posts = snapshot.data!.docs;

        // Sort posts by timestamp in ascending order (oldest first)
        posts.sort((a, b) {
          Timestamp timestampA = a['timestamp'] ?? Timestamp(0, 0);
          Timestamp timestampB = b['timestamp'] ?? Timestamp(0, 0);
          return timestampA.compareTo(timestampB);
        });

        return ListView.builder(
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            final postData = post.data() as Map<String, dynamic>; // Cast to Map

            // Filter pending requests
            if (postData['status'] != 'Pending') {
              return const SizedBox.shrink(); // Skip non-pending requests
            }

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      postData['title'] ?? 'N/A', // Use N/A if title is null
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      postData['content'] ??
                          'N/A', // Use N/A if content is null
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      postData['timestamp'] != null
                          ? (postData['timestamp'] as Timestamp)
                              .toDate()
                              .toString()
                          : 'N/A', // Use N/A if timestamp is null
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Status: ${postData['status'] ?? 'Pending'}', // Default to 'Pending'
                      style: const TextStyle(color: Colors.blue),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            // Show a loading indicator while processing
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (BuildContext context) {
                                return Center(
                                    child: CircularProgressIndicator());
                              },
                            );

                            try {
                              // Accept the post and update the status to 'Accepted'
                              await FirebaseFirestore.instance
                                  .collection(
                                      'creator') // Changed from 'users' to 'creator'
                                  .doc(post
                                      .reference.parent.parent!.id) // School ID
                                  .collection('posts')
                                  .doc(post.id) // Post ID
                                  .update({
                                'status': 'Accepted'
                              }); // Set status to accepted

                              // Show success message
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Request accepted')),
                              );
                            } catch (e) {
                              // Show error message
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text('Failed to accept request: $e')),
                              );
                            } finally {
                              // Remove the loading indicator
                              Navigator.of(context).pop();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green, // Green for accept
                          ),
                          child: const Text('Accept Request'),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            // Show a loading indicator while processing
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (BuildContext context) {
                                return Center(
                                    child: CircularProgressIndicator());
                              },
                            );

                            try {
                              // Update the post's status to 'Declined'
                              await FirebaseFirestore.instance
                                  .collection(
                                      'creator') // Changed from 'users' to 'creator'
                                  .doc(post
                                      .reference.parent.parent!.id) // School ID
                                  .collection('posts')
                                  .doc(post.id) // Post ID
                                  .update({
                                'status': 'Declined'
                              }); // Set status to declined

                              // Show success message
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Request declined')),
                              );
                            } catch (e) {
                              // Show error message
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text('Failed to decline request: $e')),
                              );
                            } finally {
                              // Remove the loading indicator
                              Navigator.of(context).pop();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red, // Red for decline
                          ),
                          child: const Text('Decline Request'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

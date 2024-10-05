import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Importing intl package for date formatting

class AcceptedTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return buildPostsList('Accepted');
  }

  Widget buildPostsList(String statusFilter) {
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

        // Filter posts based on the status
        final filteredPosts = posts.where((post) {
          final postData = post.data() as Map<String, dynamic>;
          return postData['status'] == statusFilter;
        }).toList();

        if (filteredPosts.isEmpty) {
          return const Center(
              child: Text('No requests found for this status.'));
        }

        // Sort posts by timestamp in ascending order
        filteredPosts.sort((a, b) {
          Timestamp timestampA = a['timestamp'] ?? Timestamp(0, 0);
          Timestamp timestampB = b['timestamp'] ?? Timestamp(0, 0);
          return timestampA.compareTo(timestampB);
        });

        return ListView.builder(
          itemCount: filteredPosts.length,
          itemBuilder: (context, index) {
            final post = filteredPosts[index];
            final postData = post.data() as Map<String, dynamic>;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      postData['title'] ?? 'N/A',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      postData['content'] ?? 'N/A',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      postData['timestamp'] != null
                          ? DateFormat('MMMM-dd-yyyy hh:mm a').format(
                              (postData['timestamp'] as Timestamp).toDate())
                          : 'N/A',
                      style: const TextStyle(color: Colors.grey),
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

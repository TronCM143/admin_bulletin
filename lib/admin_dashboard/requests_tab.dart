import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Importing intl package for date formatting

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

        // Sort posts by timestamp in descending order (newest first)
        posts.sort((a, b) {
          Timestamp timestampA = a['timestamp'] ?? Timestamp(0, 0);
          Timestamp timestampB = b['timestamp'] ?? Timestamp(0, 0);
          return timestampB.compareTo(timestampA);
        });

        // Filter pending requests
        final pendingPosts = posts.where((post) {
          final postData = post.data() as Map<String, dynamic>;
          return postData['status'] == 'Pending';
        }).toList();

        return ListView.builder(
          itemCount: pendingPosts.length,
          itemBuilder: (context, index) {
            final post = pendingPosts[index];
            final postData = post.data() as Map<String, dynamic>;

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('creator')
                  .doc(post.reference.parent.parent!.id)
                  .get(),
              builder:
                  (context, AsyncSnapshot<DocumentSnapshot> creatorSnapshot) {
                if (creatorSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!creatorSnapshot.hasData || !creatorSnapshot.data!.exists) {
                  return const Center(
                      child: Text('Creator information not available.'));
                }

                final creatorData =
                    creatorSnapshot.data!.data() as Map<String, dynamic>;
                final department = creatorData['department'] ?? 'Unknown';
                final clubName = creatorData['clubName'] ?? 'Unknown Club';

                return Card(
                  margin:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          clubName, // Displaying the club name
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4), // Small spacing
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
                              ? DateFormat('MMMM-dd-yyyy').format(
                                      (postData['timestamp'] as Timestamp)
                                          .toDate()) +
                                  ' ' +
                                  DateFormat('hh:mm a').format(
                                      (postData['timestamp'] as Timestamp)
                                          .toDate())
                              : 'N/A',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Department: $department',
                          style: const TextStyle(color: Colors.blue),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Status: ${postData['status'] ?? 'Pending'}',
                          style: const TextStyle(color: Colors.blue),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (BuildContext context) {
                                    return Center(
                                        child: CircularProgressIndicator());
                                  },
                                );

                                try {
                                  await FirebaseFirestore.instance
                                      .collection('creator')
                                      .doc(post.reference.parent.parent!.id)
                                      .collection('posts')
                                      .doc(post.id)
                                      .update({'status': 'Accepted'});

                                  await FirebaseFirestore.instance
                                      .collection('requests')
                                      .doc('accepted')
                                      .collection('accepted_requests')
                                      .add({
                                    'title': postData['title'],
                                    'content': postData['content'],
                                    'timestamp': postData['timestamp'],
                                    'status': 'Accepted',
                                    'creatorId':
                                        post.reference.parent.parent!.id,
                                  });

                                  await FirebaseFirestore.instance
                                      .collection(department)
                                      .add({
                                    'title': postData['title'],
                                    'content': postData['content'],
                                    'timestamp': postData['timestamp'],
                                    'status': 'Accepted',
                                    'creatorId':
                                        post.reference.parent.parent!.id,
                                  });

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'Request accepted and moved to $department and accepted collection')),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'Failed to accept request: $e')),
                                  );
                                } finally {
                                  Navigator.of(context).pop();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                              child: const Text('Accept Request'),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (BuildContext context) {
                                    return Center(
                                        child: CircularProgressIndicator());
                                  },
                                );

                                try {
                                  await FirebaseFirestore.instance
                                      .collection('creator')
                                      .doc(post.reference.parent.parent!.id)
                                      .collection('posts')
                                      .doc(post.id)
                                      .update({'status': 'Declined'});

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Request declined')),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'Failed to decline request: $e')),
                                  );
                                } finally {
                                  Navigator.of(context).pop();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
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
      },
    );
  }
}

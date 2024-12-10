import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import 'image_preview.dart';

class PostTable extends StatelessWidget {
  final List<QueryDocumentSnapshot> allPosts;
  final Map<String, String> postStatusMap;
  final Function(String postId, String status) onUpdateStatus;

  const PostTable({
    super.key,
    required this.allPosts,
    required this.postStatusMap,
    required this.onUpdateStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, // Align to the top-left
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8.0),
          child: Text(
            'Posts',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(
                  Colors.transparent), // Transparent header background
              dataRowColor: MaterialStateProperty.resolveWith<Color?>(
                (Set<MaterialState> states) {
                  // Transparent data row background
                  if (states.contains(MaterialState.selected)) {
                    return Colors.grey
                        .withOpacity(0.2); // Slight tint on selection
                  }
                  return Colors.transparent; // Default transparent background
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
                final truncatedContent = content.length > 30
                    ? '${content.substring(0, 30)}...'
                    : content;
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
                  DataCell(Text(truncatedContent)),
                  DataCell(
                    Wrap(
                      spacing: 8.0,
                      children: imageUrls.map<Widget>((imageUrl) {
                        return GestureDetector(
                          onTap: () {
                            showImagePreview(context, imageUrl);
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
                                    onUpdateStatus(postId, 'accepted'),
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.close, color: Colors.red),
                                onPressed: () =>
                                    onUpdateStatus(postId, 'rejected'),
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
        ),
      ],
    );
  }
}

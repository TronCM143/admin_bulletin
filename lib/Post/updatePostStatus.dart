import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PostStatusUpdater {
  // Method to update the post status in Firestore and UI
  static Future<void> updatePostStatus({
    required BuildContext context,
    required String postId,
    required String status,
    required String adminUsername,
    required Function(String postId) onPostRemoved,
  }) async {
    if (adminUsername.isEmpty) {
      print("Admin username is not set");
      return;
    }

    try {
      // Update the specific admin's approval document in Firestore
      await FirebaseFirestore.instance
          .collection('Posts')
          .doc(postId)
          .collection('approvals')
          .doc(adminUsername) // Use the dynamic username here
          .set({'status': status}, SetOptions(merge: true));

      // Call the callback function to update the local state
      onPostRemoved(postId);

      // Show a confirmation message
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Post status updated to $status')));
    } catch (error) {
      print('Error updating status: $error');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $error')));
    }
  }
}

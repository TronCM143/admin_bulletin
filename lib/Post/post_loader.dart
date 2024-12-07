import 'package:cloud_firestore/cloud_firestore.dart';

class PostLoader {
  // Method to fetch filtered posts based on the admin's username
  static Future<void> loadFilteredPosts({
    required String adminUsername,
    required Function(List<QueryDocumentSnapshot> posts) onPostsLoaded,
    required Function onLoadingComplete,
    required Function onError,
  }) async {
    if (adminUsername.isEmpty) {
      print("Admin username is not set");
      onLoadingComplete(); // Stop loading if no username
      return;
    }

    try {
      // Fetch all posts first
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('Posts').get();

      print('Total posts fetched: ${snapshot.docs.length}'); // Debugging

      List<QueryDocumentSnapshot> filteredPosts = [];

      // Loop through each post and query the 'approvals' subcollection
      for (var postDoc in snapshot.docs) {
        // Fetch the 'approvals' subcollection for each post
        QuerySnapshot approvalsSnapshot = await FirebaseFirestore.instance
            .collection('Posts')
            .doc(postDoc.id)
            .collection('approvals')
            .where('status', isEqualTo: 'pending')
            .where('adminId',
                isEqualTo: adminUsername) // Adjust to match the admin
            .get();

        if (approvalsSnapshot.docs.isNotEmpty) {
          filteredPosts.add(
              postDoc); // Add the post to filtered list if it matches the conditions
        }
      }

      // Callback to update posts in the UI
      onPostsLoaded(filteredPosts);
    } catch (error) {
      print('Error loading filtered posts: $error');
      onError(); // Callback for error handling
    } finally {
      onLoadingComplete(); // Ensure loading is stopped
    }
  }
}

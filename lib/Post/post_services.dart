import 'package:cloud_firestore/cloud_firestore.dart';

class PostService {
  static Future<List<QueryDocumentSnapshot>> fetchPosts(String username) async {
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

  static Future<String?> fetchPostStatus(String username, String postId) async {
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

  static Future<void> updatePostStatus(
      String username, String postId, String status) async {
    await FirebaseFirestore.instance
        .collection('Posts')
        .doc(postId)
        .collection('approvals')
        .doc(username)
        .update({'status': status});
  }

  static String _getDepartmentFromUsername(String username) {
    if (username.endsWith('_DEAN')) {
      return username.split('_')[0];
    } else if (['ACAD_VP', 'ADMIN_VP', 'DSA', 'QUAPS'].contains(username)) {
      return 'default';
    }
    return 'default';
  }
}

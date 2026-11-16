import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/jeweler_profile.dart';

class JewelerService {
  const JewelerService({this.firestore});

  final FirebaseFirestore? firestore;

  Future<JewelerProfile?> fetchApprovedJeweler(String jewelerId) async {
    final normalizedId = jewelerId.trim();
    if (normalizedId.isEmpty) {
      throw ArgumentError.value(jewelerId, 'jewelerId', 'Must not be empty.');
    }

    final database = firestore ?? FirebaseFirestore.instance;
    final document = await database
        .collection('applications')
        .doc(normalizedId)
        .get();
    final data = document.data();

    if (!document.exists || data == null || data['status'] != 'approved') {
      return null;
    }

    return JewelerProfile.fromFirestore(document.id, data);
  }
}

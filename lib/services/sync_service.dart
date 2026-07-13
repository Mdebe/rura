import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../database/db_helper.dart';
import '../models/site.dart';
import 'cloudinary_service.dart';

class SyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CloudinaryService _cloudinary = CloudinaryService();

  Future<int> pushToFirebase() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');

    final unsyncedSites = await DBHelper.instance.getUnsyncedSites();
    if (unsyncedSites.isEmpty) return 0;

    int syncedCount = 0;
    final batch = _firestore.batch();

    for (final site in unsyncedSites) {
      try {
        final docRef = site.firestoreId != null
            ? _firestore.collection('sites').doc(site.firestoreId)
            : _firestore.collection('sites').doc();

        final data = site.toFirestore();
        data['createdByUid'] = user.uid;
        data['createdBy'] = user.email;
        data['createdByName'] = user.displayName ?? user.email;
        data['lastUpdated'] = FieldValue.serverTimestamp();

        batch.set(docRef, data, SetOptions(merge: true));

        // Update local DB with firestoreId
        await DBHelper.instance.markSiteSynced(site.id!, docRef.id);
        syncedCount++;
      } catch (e) {
        print('Failed to sync site ${site.siteCode}: $e');
      }
    }

    if (syncedCount > 0) {
      await batch.commit();
    }

    return syncedCount;
  }

  /// NEW: Upload pending images to Cloudinary
  Future<int> uploadPendingImages() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');

    final sites = await DBHelper.instance.getSitesWithUnsyncedImages();
    if (sites.isEmpty) return 0;

    int uploadedCount = 0;

    for (final site in sites) {
      if (site.imagePaths == null || site.imagePaths!.isEmpty) continue;

      try {
        final urls = await _cloudinary.uploadMultipleImages(site.imagePaths!);
        if (urls.isNotEmpty) {
          await DBHelper.instance.markImagesSynced(site.id!, urls);
          uploadedCount++;
        }
      } catch (e) {
        print('Failed to upload images for site ${site.siteCode}: $e');
        await DBHelper.instance.markSyncError(
          site.id!,
          'Image upload failed: $e',
        );
      }
    }

    return uploadedCount;
  }

  Future<void> syncFromFirebase() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await _firestore
        .collection('sites')
        .where('createdByUid', isEqualTo: user.uid)
        .get();

    for (final doc in snapshot.docs) {
      final site = Site.fromFirestore(doc);
      final existing = await DBHelper.instance.getSiteByFirestoreId(doc.id);

      if (existing == null) {
        await DBHelper.instance.insertSite(site);
      } else if (site.lastUpdated?.isAfter(
            existing.lastUpdated ?? DateTime(2000),
          ) ==
          true) {
        await DBHelper.instance.updateSite(
          site.copyWith(id: existing.id, isSynced: true),
        );
      }
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../database/db_helper.dart';
import '../models/site.dart';

class SiteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DBHelper _db = DBHelper.instance;

  Future<Site> saveSite(Site site) async {
    // 1. Save to SQLite first with isSynced = false
    final localId = await _db.insertSite(site.copyWith(isSynced: false));
    Site localSite = site.copyWith(id: localId, isSynced: false);

    // 2. Push to Firestore
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not logged in');

      final docRef = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('sites')
          .add(localSite.toFirestore()); // Use toFirestore(), not toMap()

      // 3. Update SQLite with firestore_id and isSynced = true
      localSite = localSite.copyWith(firestoreId: docRef.id, isSynced: true);
      await _db.updateSite(localSite);

      return localSite;
    } catch (e) {
      // If Firestore fails, it stays isSynced = false for retry later
      print('Firestore sync failed: $e');
      return localSite; // Return unsynced site
    }
  }

  Future<void> syncPendingSites() async {
    final unsynced = await _db.getUnsyncedSites();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    for (var site in unsynced) {
      try {
        final docRef = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('sites')
            .add(site.toFirestore()); // Use toFirestore()

        await _db.updateSite(
          site.copyWith(
            firestoreId: docRef.id,
            isSynced: true, // bool, not 1
          ),
        );
      } catch (e) {
        print('Sync failed for site ${site.id}: $e');
      }
    }
  }

  Future<List<Site>> getLocalSites() async {
    return await _db.getAllSites();
  }

  Future<void> deleteSite(Site site) async {
    // Delete from SQLite
    if (site.id != null) {
      await _db.deleteSite(site.id!);
    }

    // Delete from Firestore if synced
    if (site.firestoreId != null) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('sites')
              .doc(site.firestoreId!)
              .delete();
        }
      } catch (e) {
        print('Firestore delete failed: $e');
      }
    }
  }
}

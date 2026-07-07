import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/site.dart';
import '../database/db_helper.dart';

class SyncService {
  final _firestore = FirebaseFirestore.instance;
  final _db = DBHelper.instance;

  Future<int> pushToFirebase() async {
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none) || connectivity.isEmpty) {
      return 0;
    }

    final db = await _db.database;
    final unsynced = await db.query(
      'sites',
      where: 'isSynced =?',
      whereArgs: [0],
    );

    int syncedCount = 0;
    for (final map in unsynced) {
      final site = Site.fromMap(map);
      try {
        DocumentReference docRef;
        if (site.firestoreId == null) {
          docRef = await _firestore.collection('sites').add(site.toFirestore());
        } else {
          docRef = _firestore.collection('sites').doc(site.firestoreId);
          await docRef.set(site.toFirestore(), SetOptions(merge: true));
        }

        await db.update(
          'sites',
          {'isSynced': 1, 'firestore_id': docRef.id},
          where: 'id =?',
          whereArgs: [site.id],
        );
        syncedCount++;
      } catch (e) {
        print('Sync error for site ${site.id}: $e');
      }
    }
    return syncedCount;
  }

  Future<int> pullFromFirebase() async {
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none) || connectivity.isEmpty) {
      return 0;
    }

    final snapshot = await _firestore.collection('sites').get();
    final db = await _db.database;
    int pulledCount = 0;

    for (final doc in snapshot.docs) {
      final existing = await db.query(
        'sites',
        where: 'firestore_id =?',
        whereArgs: [doc.id],
        limit: 1,
      );

      final site = Site.fromFirestore(doc);
      if (existing.isEmpty) {
        await db.insert('sites', site.toMap()..remove('id'));
        pulledCount++;
      } else {
        await db.update(
          'sites',
          site.toMap(),
          where: 'firestore_id =?',
          whereArgs: [doc.id],
        );
      }
    }
    return pulledCount;
  }

  // FIX: Return total count instead of void
  Future<int> fullSync() async {
    final pushed = await pushToFirebase();
    final pulled = await pullFromFirebase();
    return pushed + pulled; // Return total synced
  }
}
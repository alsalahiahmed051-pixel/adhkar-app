import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/dhikr_item.dart';
import '../models/category.dart';

/// All "public"/shared data lives in Firestore so it's the same for every
/// user — this is the real backend behind the web prototype's
/// `window.storage(..., shared:true)` calls, except now it's genuinely
/// real-time (no 9-second polling needed) and counter increments are
/// atomic via FieldValue.increment.
class FirestoreService {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _communityItems => _db.collection('community_items');
  CollectionReference<Map<String, dynamic>> get _pendingItems => _db.collection('pending_items');
  CollectionReference<Map<String, dynamic>> get _pendingCategories => _db.collection('pending_categories');
  CollectionReference<Map<String, dynamic>> get _customCategories => _db.collection('custom_categories');

  Stream<List<DhikrItem>> watchCommunityItems() => _communityItems
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => DhikrItem.fromMap(d.data(), d.id)).toList());

  Stream<List<DhikrItem>> watchPendingItems() => _pendingItems
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => DhikrItem.fromMap(d.data(), d.id)).toList());

  Stream<List<DhikrCategory>> watchPendingCategories() => _pendingCategories
      .snapshots()
      .map((s) => s.docs.map((d) => DhikrCategory.fromMap({...d.data(), 'id': d.id})).toList());

  Stream<List<DhikrCategory>> watchCustomCategories() => _customCategories
      .snapshots()
      .map((s) => s.docs.map((d) => DhikrCategory.fromMap({...d.data(), 'id': d.id})).toList());

  /// New community submission — goes to the *pending* queue first so an
  /// admin can review it before it appears for everyone (the share code
  /// works immediately for whoever has it, even pre-approval).
  Future<void> submitForReview(DhikrItem item) =>
      _pendingItems.doc(item.id).set(item.toMap());

  Future<void> approveItem(DhikrItem item) async {
    final batch = _db.batch();
    batch.delete(_pendingItems.doc(item.id));
    batch.set(_communityItems.doc(item.id), item.toMap());
    await batch.commit();
  }

  Future<void> rejectItem(String id) => _pendingItems.doc(id).delete();

  Future<void> proposeCategory(DhikrCategory cat) =>
      _pendingCategories.doc(cat.id).set(cat.toMap());

  Future<void> approveCategory(DhikrCategory cat) async {
    final batch = _db.batch();
    batch.delete(_pendingCategories.doc(cat.id));
    batch.set(_customCategories.doc(cat.id), cat.toMap());
    await batch.commit();
  }

  Future<void> rejectCategory(String id) => _pendingCategories.doc(id).delete();

  /// Atomic increment — safe even if two people tap the shared counter
  /// at the same moment (unlike a naive read-modify-write).
  Future<void> incrementCount(String id, {required bool isPending}) =>
      (isPending ? _pendingItems : _communityItems).doc(id).update({'count': FieldValue.increment(1)});

  Future<void> resetCount(String id, {required bool isPending}) =>
      (isPending ? _pendingItems : _communityItems).doc(id).update({'count': 0});

  Future<DhikrItem?> findByShareCode(String code) async {
    for (final col in [_communityItems, _pendingItems]) {
      final q = await col.where('shareCode', isEqualTo: code.toUpperCase()).limit(1).get();
      if (q.docs.isNotEmpty) return DhikrItem.fromMap(q.docs.first.data(), q.docs.first.id);
    }
    return null;
  }

  /// Uploads a picked file to Firebase Storage and returns its download URL.
  Future<String> uploadFile(File file, String folder, String fileName) async {
    final ref = FirebaseStorage.instance.ref('$folder/${DateTime.now().millisecondsSinceEpoch}_$fileName');
    final task = await ref.putFile(file);
    return task.ref.getDownloadURL();
  }
}

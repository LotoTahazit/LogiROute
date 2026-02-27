import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// שירות שרשרת שלמות (integrity chain)
/// כל מסמך שעבר סיום מקבל hash שמבוסס על ה-hash של המסמך הקודם
/// אוסף: companies/{cId}/integrity_chain/{chainId}
///
/// מבנה: prevHash + documentHash + sequentialNumber + timestamp → chainHash
/// אם מישהו שינה מסמך ישן — כל ה-chain מהנקודה הזו נשבר
class IntegrityChainService {
  final String companyId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  IntegrityChainService({required this.companyId});

  CollectionReference<Map<String, dynamic>> _chainCollection() {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('accounting')
        .doc('_root')
        .collection('integrity_chain');
  }

  /// הוספת חוליה חדשה לשרשרת
  Future<String> appendToChain({
    required String documentId,
    required String documentType,
    required int sequentialNumber,
    required String documentHash,
  }) async {
    // קבלת ה-hash האחרון בשרשרת
    final lastEntry = await _getLastChainEntry();
    final prevHash = lastEntry?['chainHash'] as String? ?? 'GENESIS';

    // חישוב hash חדש
    final chainHash = _computeChainHash(
      prevHash: prevHash,
      documentHash: documentHash,
      sequentialNumber: sequentialNumber,
      documentType: documentType,
    );

    final entry = {
      'documentId': documentId,
      'documentType': documentType,
      'sequentialNumber': sequentialNumber,
      'documentHash': documentHash,
      'prevHash': prevHash,
      'chainHash': chainHash,
      'timestamp': FieldValue.serverTimestamp(),
      'chainIndex': (lastEntry?['chainIndex'] as int? ?? 0) + 1,
    };

    final docRef = await _chainCollection().add(entry);
    return docRef.id;
  }

  /// אימות שלמות השרשרת — בודק שכל חוליה תואמת לקודמתה
  Future<IntegrityVerificationResult> verifyChain() async {
    final snapshot = await _chainCollection().orderBy('chainIndex').get();

    if (snapshot.docs.isEmpty) {
      return IntegrityVerificationResult(valid: true, checkedCount: 0);
    }

    String expectedPrevHash = 'GENESIS';
    int checked = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final storedPrevHash = data['prevHash'] as String? ?? '';
      final storedChainHash = data['chainHash'] as String? ?? '';

      // בדיקה 1: prevHash תואם
      if (storedPrevHash != expectedPrevHash) {
        return IntegrityVerificationResult(
          valid: false,
          checkedCount: checked,
          brokenAtIndex: data['chainIndex'] as int?,
          brokenDocumentId: data['documentId'] as String?,
          error: 'prevHash mismatch at index ${data['chainIndex']}',
        );
      }

      // בדיקה 2: chainHash מחושב נכון
      final recomputedHash = _computeChainHash(
        prevHash: storedPrevHash,
        documentHash: data['documentHash'] as String? ?? '',
        sequentialNumber: data['sequentialNumber'] as int? ?? 0,
        documentType: data['documentType'] as String? ?? '',
      );

      if (recomputedHash != storedChainHash) {
        return IntegrityVerificationResult(
          valid: false,
          checkedCount: checked,
          brokenAtIndex: data['chainIndex'] as int?,
          brokenDocumentId: data['documentId'] as String?,
          error: 'chainHash mismatch at index ${data['chainIndex']}',
        );
      }

      expectedPrevHash = storedChainHash;
      checked++;
    }

    return IntegrityVerificationResult(valid: true, checkedCount: checked);
  }

  Future<Map<String, dynamic>?> _getLastChainEntry() async {
    final snapshot = await _chainCollection()
        .orderBy('chainIndex', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return snapshot.docs.first.data();
  }

  String _computeChainHash({
    required String prevHash,
    required String documentHash,
    required int sequentialNumber,
    required String documentType,
  }) {
    final input = '$prevHash|$documentHash|$sequentialNumber|$documentType';
    return sha256.convert(utf8.encode(input)).toString();
  }

  // === עוגן חיצוני (External Anchor) ===

  CollectionReference<Map<String, dynamic>> _anchorsCollection() {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('accounting')
        .doc('_root')
        .collection('integrity_anchors');
  }

  /// יצירת עוגן חיצוני — snapshot של ה-hash האחרון
  /// מומלץ: פעם ברבעון, או לפני גיבוי
  Future<IntegrityAnchor?> createAnchor({
    required String anchoredBy,
    String? externalRef,
  }) async {
    final lastEntry = await _getLastChainEntry();
    if (lastEntry == null) return null;

    final anchor = IntegrityAnchor(
      chainHash: lastEntry['chainHash'] as String,
      chainIndex: lastEntry['chainIndex'] as int,
      anchoredAt: DateTime.now(),
      anchoredBy: anchoredBy,
      externalRef: externalRef,
    );

    await _anchorsCollection().add(anchor.toMap());
    return anchor;
  }

  /// אימות עוגן — בודק שה-hash בשרשרת תואם לעוגן
  Future<bool> verifyAnchor(String anchorId) async {
    final anchorDoc = await _anchorsCollection().doc(anchorId).get();
    if (!anchorDoc.exists) return false;

    final anchorData = anchorDoc.data()!;
    final anchorHash = anchorData['chainHash'] as String;
    final anchorIndex = anchorData['chainIndex'] as int;

    final chainDoc = await _chainCollection()
        .where('chainIndex', isEqualTo: anchorIndex)
        .limit(1)
        .get();

    if (chainDoc.docs.isEmpty) return false;
    return chainDoc.docs.first.data()['chainHash'] == anchorHash;
  }

  /// קבלת כל העוגנים
  Future<List<Map<String, dynamic>>> getAnchors({int limit = 10}) async {
    final snapshot = await _anchorsCollection()
        .orderBy('anchoredAt', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }
}

/// תוצאת אימות שרשרת שלמות
class IntegrityVerificationResult {
  final bool valid;
  final int checkedCount;
  final int? brokenAtIndex;
  final String? brokenDocumentId;
  final String? error;

  IntegrityVerificationResult({
    required this.valid,
    required this.checkedCount,
    this.brokenAtIndex,
    this.brokenDocumentId,
    this.error,
  });
}

/// עוגן חיצוני — snapshot של ה-hash האחרון בשרשרת
/// נשמר ב-companies/{cId}/integrity_anchors/{anchorId}
/// ניתן לייצא ל-Cloud Storage / Git / external log
class IntegrityAnchor {
  final String chainHash;
  final int chainIndex;
  final DateTime anchoredAt;
  final String anchoredBy;
  final String? externalRef;

  IntegrityAnchor({
    required this.chainHash,
    required this.chainIndex,
    required this.anchoredAt,
    required this.anchoredBy,
    this.externalRef,
  });

  Map<String, dynamic> toMap() => {
        'chainHash': chainHash,
        'chainIndex': chainIndex,
        'anchoredAt': FieldValue.serverTimestamp(),
        'anchoredBy': anchoredBy,
        if (externalRef != null) 'externalRef': externalRef,
      };
}

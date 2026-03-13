import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/document_link.dart';

/// שירות קישורים בין מסמכים חשבונאיים
/// אוסף: companies/{cId}/document_links/{linkId}
class DocumentLinkService {
  final String companyId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DocumentLinkService({required this.companyId});

  CollectionReference<Map<String, dynamic>> _linksCollection() {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('document_links');
  }

  /// יצירת קישור בין מסמכים
  Future<String> createLink(DocumentLink link) async {
    final docRef = await _linksCollection().add(link.toMap());
    return docRef.id;
  }

  /// קבלת כל הקישורים של מסמך (כמקור או כיעד)
  Future<List<DocumentLink>> getLinksForDocument(String documentId) async {
    // שאילתה 1: מסמך כמקור
    final sourceSnapshot = await _linksCollection()
        .where('sourceDocumentId', isEqualTo: documentId)
        .get();

    // שאילתה 2: מסמך כיעד
    final targetSnapshot = await _linksCollection()
        .where('targetDocumentId', isEqualTo: documentId)
        .get();

    final links = <DocumentLink>[];
    for (final doc in sourceSnapshot.docs) {
      links.add(DocumentLink.fromMap(doc.data(), doc.id));
    }
    for (final doc in targetSnapshot.docs) {
      links.add(DocumentLink.fromMap(doc.data(), doc.id));
    }

    return links;
  }

  /// קבלת קישורים לפי סוג
  Future<List<DocumentLink>> getLinksByType(DocumentLinkType linkType) async {
    final snapshot = await _linksCollection()
        .where('linkType', isEqualTo: linkType.name)
        .get();

    return snapshot.docs
        .map((doc) => DocumentLink.fromMap(doc.data(), doc.id))
        .toList();
  }
}

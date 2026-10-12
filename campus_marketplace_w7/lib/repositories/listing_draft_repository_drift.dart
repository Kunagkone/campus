import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../models/listing_draft.dart';
import 'listing_draft_repository.dart';

class ListingDraftRepositoryDrift implements ListingDraftRepository {
  final AppDatabase _db;

  ListingDraftRepositoryDrift(this._db);

  @override
  Future<void> saveDraft(ListingDraft draft) async {
    await _db.delete(_db.listingDrafts).go();
    await _db.into(_db.listingDrafts).insert(
          ListingDraftsCompanion.insert(
            title: draft.title,
            category: draft.category,
            description: draft.description,
            imagePath: draft.imagePath ?? '',
          ),
        );
  }

  @override
  Future<ListingDraft?> getDraft() async {
    final rows = await (_db.select(_db.listingDrafts)
          ..orderBy([(t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc)])
          ..limit(1))
        .get();

    if (rows.isEmpty) return null;

    final row = rows.first;
    return ListingDraft(
      title: row.title,
      category: row.category,
      description: row.description,
      imagePath: row.imagePath.isEmpty ? null : row.imagePath,
    );
  }

  @override
  Future<void> deleteDraft() async {
    await _db.delete(_db.listingDrafts).go();
  }
}
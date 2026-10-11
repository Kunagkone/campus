import '../models/listing_draft.dart';

abstract class ListingDraftRepository {
  Future<void> saveDraft(ListingDraft draft);
  Future<ListingDraft?> getDraft();
  Future<void> deleteDraft();
}
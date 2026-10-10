import 'package:drift/drift.dart';

// ตารางที่ 1: รายการสินค้าโปรด (Favorites)
class FavoriteItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get itemId => integer().unique()(); // .unique() ป้องกันการกดถูกใจสินค้าชิ้นเดิมซ้ำ
  TextColumn get title => text()();
  RealColumn get price => real()();
  TextColumn get imageUrl => text()();
  DateTimeColumn get addedAt => dateTime().withDefault(currentDateAndTime)();
}

// ตารางที่ 2: ร่างประกาศขายสินค้า (Listing Drafts)
@DataClassName('ListingDraftRow') // ตั้งชื่อ Class เพื่อไม่ให้ซ้ำกับ ListingDraft ในสัปดาห์ที่ 7
class ListingDrafts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 100)();
  TextColumn get category => text()();
  TextColumn get description => text()();
  TextColumn get imagePath => text()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
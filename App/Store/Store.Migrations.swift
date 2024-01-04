import GRDB

extension Store {
	/// Creates and maintains database schema
	var databaseMigrator: DatabaseMigrator {
		var migrator = DatabaseMigrator()
		migrator.registerMigration("v1") { database in
			try database.create(table: "feed") {
				$0.column("source", .text).primaryKey(onConflict: .replace)
				$0.column("title", .text)
				$0.column("icon", .text)
			}
			try database.create(table: "item") {
				$0.column("id", .integer).primaryKey(onConflict: .replace)
				$0.column("source", .text).notNull().references("feed", onDelete: .cascade)
				$0.column("title", .text).notNull()
				$0.column("time", .double)
				$0.column("author", .text)
				$0.column("content", .text)
				$0.column("url", .text)
				$0.column("isRead", .boolean)
				$0.column("isStarred", .boolean)
				$0.column("sync", .blob)
				$0.column("extracted", .text)
			}
			try database.create(table: "attachment") {
				$0.column("itemId").notNull().references("item", column: "id", onDelete: .cascade)
				$0.column("url").primaryKey(onConflict: .replace)
				$0.column("mime")
				$0.column("title")
			}
		}
		return migrator
	}
}

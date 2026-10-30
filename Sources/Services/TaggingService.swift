import Foundation
import SwiftData

struct TaggingService {

    let modelContext: ModelContext

    // MARK: – CRUD

    func createTag(name: String, colorHex: String) -> Tag {
        let tag = Tag(name: name, colorHex: colorHex)
        modelContext.insert(tag)
        try? modelContext.save()
        return tag
    }

    func deleteTag(_ tag: Tag) {
        modelContext.delete(tag)
        try? modelContext.save()
    }

    func fetchAllTags() -> [Tag] {
        let descriptor = FetchDescriptor<Tag>(sortBy: [SortDescriptor(\.name)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: – Assignment

    func assignTag(_ tag: Tag, to session: TimerSession) {
        guard !session.tags.contains(where: { $0.id == tag.id }) else { return }
        session.tags.append(tag)
        try? modelContext.save()
    }

    func removeTag(_ tag: Tag, from session: TimerSession) {
        session.tags.removeAll { $0.id == tag.id }
        try? modelContext.save()
    }

    // MARK: – Seeding

    func seedDefaultTags() {
        let existing = fetchAllTags()
        guard existing.isEmpty else { return }

        for (name, hex) in Tag.seedTags {
            let tag = Tag(name: name, colorHex: hex)
            modelContext.insert(tag)
        }
        try? modelContext.save()
    }
}

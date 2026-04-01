import Testing

@testable import mkdnLib

@Suite("HelpSection")
struct HelpSectionTests {
    @Test("All sections have unique IDs")
    func uniqueIDs() {
        let ids = HelpSection.allCases.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test("All sections have SF Symbol icons")
    func allHaveIcons() {
        for section in HelpSection.allCases {
            #expect(!section.icon.isEmpty)
        }
    }

    @Test("Has exactly 4 sections")
    func sectionCount() {
        #expect(HelpSection.allCases.count == 4)
    }
}

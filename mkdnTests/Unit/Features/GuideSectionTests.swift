import Testing

@testable import mkdnLib

@Suite("GuideSection")
struct GuideSectionTests {
    @Test("All sections have unique IDs")
    func uniqueIDs() {
        let ids = GuideSection.allCases.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test("All sections have SF Symbol icons")
    func allHaveIcons() {
        for section in GuideSection.allCases {
            #expect(!section.icon.isEmpty)
        }
    }

    @Test("Has exactly 10 sections")
    func sectionCount() {
        #expect(GuideSection.allCases.count == 10)
    }

    @Test("Mermaid section exists")
    func mermaidExists() {
        #expect(GuideSection.allCases.contains(.mermaid))
    }
}

import Testing
@testable import Reviso

struct SubjectDataTests {

    @Test func subjects_containsExpectedCount() {
        #expect(SubjectData.all.count == 7)
    }

    @Test func subjects_mathHasExpectedSubTopics() {
        let math = SubjectData.all.first { $0.name == "Math" }
        #expect(math != nil)
        #expect(math?.subTopics.contains("Arithmetic") == true)
        #expect(math?.subTopics.contains("Fractions") == true)
        #expect(math?.subTopics.contains("Algebra") == true)
    }

    @Test func subjects_generalIsLast() {
        #expect(SubjectData.all.last?.name == "General")
    }

    @Test func subjectNames_returnsAllNames() {
        let names = SubjectData.subjectNames
        #expect(names.contains("Math"))
        #expect(names.contains("English"))
        #expect(names.contains("General"))
        #expect(names.count == 7)
    }

    @Test func subTopics_returnsCorrectListForSubject() {
        let topics = SubjectData.subTopics(for: "Science")
        #expect(topics.contains("Physics"))
        #expect(topics.contains("Chemistry"))
    }

    @Test func subTopics_returnsEmptyForUnknownSubject() {
        let topics = SubjectData.subTopics(for: "Unknown")
        #expect(topics.isEmpty)
    }
}

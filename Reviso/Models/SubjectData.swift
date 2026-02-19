import Foundation

struct SubjectInfo {
    let name: String
    let subTopics: [String]
}

enum SubjectData {
    static let all: [SubjectInfo] = [
        SubjectInfo(name: "Math", subTopics: ["Arithmetic", "Fractions", "Algebra", "Geometry", "Statistics"]),
        SubjectInfo(name: "English", subTopics: ["Grammar", "Vocabulary", "Comprehension", "Writing"]),
        SubjectInfo(name: "Science", subTopics: ["Physics", "Chemistry", "Biology", "General Science"]),
        SubjectInfo(name: "Chinese", subTopics: ["Reading", "Writing", "Vocabulary", "Grammar"]),
        SubjectInfo(name: "History", subTopics: ["World History", "Local History"]),
        SubjectInfo(name: "Geography", subTopics: ["Physical", "Human"]),
        SubjectInfo(name: "General", subTopics: ["Other", "Mixed"]),
    ]

    static var subjectNames: [String] {
        all.map(\.name)
    }

    static func subTopics(for subject: String) -> [String] {
        all.first { $0.name == subject }?.subTopics ?? []
    }
}

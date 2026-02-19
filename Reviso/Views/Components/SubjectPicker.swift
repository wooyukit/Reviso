import SwiftUI

struct SubjectPicker: View {
    @Binding var selectedSubject: String
    @Binding var selectedSubTopic: String?

    var body: some View {
        Picker("Subject", selection: $selectedSubject) {
            ForEach(SubjectData.subjectNames, id: \.self) { name in
                Text(name).tag(name)
            }
        }

        let subTopics = SubjectData.subTopics(for: selectedSubject)
        if !subTopics.isEmpty {
            Picker("Sub-topic", selection: Binding(
                get: { selectedSubTopic ?? subTopics[0] },
                set: { selectedSubTopic = $0 }
            )) {
                ForEach(subTopics, id: \.self) { topic in
                    Text(topic).tag(topic)
                }
            }
        }
    }
}

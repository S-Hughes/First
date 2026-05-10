import SwiftUI

struct CategoryPicker: View {
    @Binding var selection: InspectionCategory

    var body: some View {
        Picker("Category", selection: $selection) {
            ForEach(InspectionCategory.allCases) { category in
                Label(category.displayName, systemImage: category.symbolName)
                    .tag(category)
            }
        }
        .pickerStyle(.navigationLink)
    }
}

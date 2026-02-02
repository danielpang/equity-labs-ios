import SwiftUI

// MARK: - AddStockView
struct AddStockView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack {
                Text("Add Stock")
                    .font(.title)
                    .padding()

                Text("This view will be implemented in Phase 3")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)

                Spacer()
            }
            .navigationTitle("Add Stock")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    AddStockView()
}

import SwiftUI

// MARK: - StockLotsListView
struct StockLotsListView: View {
    let stock: Stock
    let onAddLot: (StockLot) -> Void
    let onUpdateLot: (StockLot) -> Void
    let onDeleteLot: (StockLot) -> Void

    @State private var showingAddLot = false
    @State private var editingLot: StockLot?
    @State private var lotToDelete: StockLot?
    @State private var showingDeleteConfirmation = false

    var body: some View {
        VStack(spacing: 0) {
            if stock.lots.isEmpty {
                emptyStateView
            } else {
                lotsList
            }
        }
    }

    // MARK: - Lots List

    private var lotsList: some View {
        VStack(spacing: 0) {
            // Summary Header
            summaryHeader

            Divider()

            // Lots List
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(stock.lots.sorted(by: { $0.purchaseDate > $1.purchaseDate })) { lot in
                        LotCardView(
                            lot: lot,
                            currentPrice: stock.currentPrice ?? stock.averageCost,
                            onEdit: {
                                editingLot = lot
                            },
                            onDelete: {
                                lotToDelete = lot
                                showingDeleteConfirmation = true
                            }
                        )
                    }

                    // Add Lot Button
                    addLotButton
                }
                .padding()
            }
        }
        .sheet(isPresented: $showingAddLot) {
            LotFormView(
                stock: stock,
                mode: .add,
                onSave: { lot in
                    onAddLot(lot)
                    showingAddLot = false
                }
            )
        }
        .sheet(item: $editingLot) { lot in
            LotFormView(
                stock: stock,
                lot: lot,
                mode: .edit,
                onSave: { updatedLot in
                    onUpdateLot(updatedLot)
                    editingLot = nil
                }
            )
        }
        .alert("Delete Lot?", isPresented: $showingDeleteConfirmation, presenting: lotToDelete) { lot in
            Button("Cancel", role: .cancel) {
                lotToDelete = nil
            }
            Button("Delete", role: .destructive) {
                onDeleteLot(lot)
                lotToDelete = nil
            }
        } message: { lot in
            Text("Are you sure you want to delete \(formatShares(lot.shares)) shares at \(formatPrice(lot.pricePerShare))?")
        }
    }

    // MARK: - Summary Header

    private var summaryHeader: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Lots Summary")
                    .font(.headline)

                Spacer()

                Text("\(stock.lots.count) lot\(stock.lots.count == 1 ? "" : "s")")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
            }

            HStack(spacing: 20) {
                // Total Shares
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Shares")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                    Text(formatShares(stock.totalShares))
                        .font(.headline)
                }

                Spacer()

                // Average Cost
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Average Cost")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                    Text(formatPrice(stock.averageCost))
                        .font(.headline)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "tray")
                .font(.system(size: 50))
                .foregroundColor(.textSecondary)

            Text("No Lots Yet")
                .font(.headline)
                .foregroundColor(.textSecondary)

            Text("Add your first lot to track your position")
                .font(.subheadline)
                .foregroundColor(.textTertiary)
                .multilineTextAlignment(.center)

            Button {
                showingAddLot = true
            } label: {
                Text("Add Lot")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .frame(maxWidth: 200)
                    .padding()
                    .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: Constants.Layout.glassCornerRadius))
            }
            .padding(.top, 8)

            Spacer()
        }
        .padding()
        .sheet(isPresented: $showingAddLot) {
            LotFormView(
                stock: stock,
                mode: .add,
                onSave: { lot in
                    onAddLot(lot)
                    showingAddLot = false
                }
            )
        }
    }

    // MARK: - Add Lot Button

    private var addLotButton: some View {
        Button {
            showingAddLot = true
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Add Another Lot")
            }
            .font(.headline)
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity)
            .padding()
            .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: Constants.Layout.glassCornerRadius))
        }
    }

    // MARK: - Formatting Helpers

    private func formatPrice(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = stock.currency
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }

    private func formatShares(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 4
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }
}

// MARK: - LotCardView
struct LotCardView: View {
    let lot: StockLot
    let currentPrice: Double
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            // Header: Date and Actions
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(lot.purchaseDate, style: .date)
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)

                    if let notes = lot.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.caption)
                            .foregroundColor(.textTertiary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Menu {
                    Button {
                        onEdit()
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }

                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .foregroundColor(.textSecondary)
                }
            }

            Divider()

            // Lot Details
            HStack(spacing: 20) {
                // Shares
                VStack(alignment: .leading, spacing: 4) {
                    Text("Shares")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                    Text(formatShares(lot.shares))
                        .font(.headline)
                }

                // Purchase Price
                VStack(alignment: .leading, spacing: 4) {
                    Text("Purchase Price")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                    Text(formatPrice(lot.pricePerShare))
                        .font(.headline)
                }

                Spacer()
            }

            Divider()

            // Performance
            HStack(spacing: 20) {
                // Cost Basis
                VStack(alignment: .leading, spacing: 4) {
                    Text("Cost Basis")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                    Text(formatPrice(lot.shares * lot.pricePerShare))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                Spacer()

                // Current Value
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Current Value")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                    Text(formatPrice(lot.shares * currentPrice))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                Spacer()

                // Gain/Loss
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Gain/Loss")
                        .font(.caption)
                        .foregroundColor(.textSecondary)

                    let gainLoss = (currentPrice - lot.pricePerShare) * lot.shares
                    let gainLossPercent = ((currentPrice - lot.pricePerShare) / lot.pricePerShare) * 100

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(formatPrice(gainLoss))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(gainLoss >= 0 ? .green : .red)

                        Text(String(format: "%+.2f%%", gainLossPercent))
                            .font(.caption)
                            .foregroundColor(gainLoss >= 0 ? .green : .red)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private func formatPrice(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = lot.currency
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }

    private func formatShares(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 4
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }
}

// MARK: - LotFormView
struct LotFormView: View {
    let stock: Stock
    var lot: StockLot?
    let mode: FormMode
    let onSave: (StockLot) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var shares: String = ""
    @State private var pricePerShare: String = ""
    @State private var purchaseDate: Date = Date()
    @State private var notes: String = ""

    enum FormMode {
        case add
        case edit
    }

    var isValid: Bool {
        guard let sharesValue = Double(shares), sharesValue > 0,
              let priceValue = Double(pricePerShare), priceValue > 0 else {
            return false
        }
        return true
    }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    // Shares
                    HStack {
                        Text("Shares")
                        Spacer()
                        TextField("0", text: $shares)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }

                    // Price Per Share
                    HStack {
                        Text("Price Per Share")
                        Spacer()
                        TextField("0.00", text: $pricePerShare)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }

                    // Purchase Date
                    DatePicker("Purchase Date", selection: $purchaseDate, displayedComponents: .date)
                } header: {
                    Text("Lot Details")
                }

                Section {
                    // Total Cost (Calculated)
                    HStack {
                        Text("Total Cost")
                            .foregroundColor(.textSecondary)
                        Spacer()
                        Text(calculateTotalCost())
                            .fontWeight(.semibold)
                    }
                } header: {
                    Text("Summary")
                }

                Section {
                    TextField("Optional notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Notes")
                }
            }
            .navigationTitle(mode == .add ? "Add Lot" : "Edit Lot")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(mode == .add ? "Add" : "Save") {
                        saveLot()
                    }
                    .disabled(!isValid)
                }
            }
            .onAppear {
                if let lot = lot {
                    // Edit mode - populate fields
                    shares = String(lot.shares)
                    pricePerShare = String(lot.pricePerShare)
                    purchaseDate = lot.purchaseDate
                    notes = lot.notes ?? ""
                }
            }
        }
    }

    private func calculateTotalCost() -> String {
        guard let sharesValue = Double(shares),
              let priceValue = Double(pricePerShare) else {
            return "$0.00"
        }

        let total = sharesValue * priceValue
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = stock.currency
        return formatter.string(from: NSNumber(value: total)) ?? "$0.00"
    }

    private func saveLot() {
        guard let sharesValue = Double(shares),
              let priceValue = Double(pricePerShare) else {
            return
        }

        let newLot = StockLot(
            id: lot?.id ?? UUID().uuidString,
            shares: sharesValue,
            pricePerShare: priceValue,
            purchaseDate: purchaseDate,
            currency: stock.currency,
            notes: notes.isEmpty ? nil : notes
        )

        onSave(newLot)
    }
}

// MARK: - Preview
#Preview("With Lots") {
    let sampleStock = Stock(
        id: "1",
        symbol: "AAPL",
        name: "Apple Inc.",
        lots: [
            StockLot(
                id: UUID().uuidString,
                shares: 10,
                pricePerShare: 150.00,
                purchaseDate: Date().addingTimeInterval(-86400 * 60),
                currency: "USD",
                notes: "First purchase"
            ),
            StockLot(
                id: UUID().uuidString,
                shares: 5,
                pricePerShare: 160.00,
                purchaseDate: Date().addingTimeInterval(-86400 * 30),
                currency: "USD",
                notes: nil
            ),
            StockLot(
                id: UUID().uuidString,
                shares: 15,
                pricePerShare: 155.00,
                purchaseDate: Date().addingTimeInterval(-86400 * 10),
                currency: "USD",
                notes: "Dip buy"
            )
        ],
        currentPrice: 165.00,
        previousClose: 163.00,
        currency: "USD",
        lastUpdated: Date()
    )

    StockLotsListView(
        stock: sampleStock,
        onAddLot: { _ in },
        onUpdateLot: { _ in },
        onDeleteLot: { _ in }
    )
}

#Preview("Empty") {
    let emptyStock = Stock(
        id: "1",
        symbol: "AAPL",
        name: "Apple Inc.",
        lots: [],
        currentPrice: 165.00,
        previousClose: 163.00,
        currency: "USD",
        lastUpdated: Date()
    )

    StockLotsListView(
        stock: emptyStock,
        onAddLot: { _ in },
        onUpdateLot: { _ in },
        onDeleteLot: { _ in }
    )
}

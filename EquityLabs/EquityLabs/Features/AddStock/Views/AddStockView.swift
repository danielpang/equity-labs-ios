import SwiftUI

// MARK: - AddStockView
struct AddStockView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = AddStockViewModel()
    @FocusState private var focusedField: Field?

    enum Field {
        case search, shares, price, notes
    }

    var body: some View {
        NavigationStack {
            Form {
                // Stock Search Section
                Section {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.textSecondary)

                        TextField("Search stocks (e.g., AAPL)", text: $viewModel.searchQuery)
                            .focused($focusedField, equals: .search)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()

                        if viewModel.isSearching {
                            ProgressView()
                                .scaleEffect(0.8)
                        }

                        if !viewModel.searchQuery.isEmpty {
                            Button {
                                viewModel.clearSelection()
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.textSecondary)
                            }
                        }
                    }

                    // Search Results
                    if !viewModel.searchResults.isEmpty {
                        ForEach(viewModel.searchResults) { result in
                            Button {
                                HapticManager.impact(.light)
                                viewModel.selectStock(result)
                                focusedField = .shares
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(result.symbol)
                                        .font(.headline)
                                        .foregroundColor(.primary)

                                    Text(result.name)
                                        .font(.subheadline)
                                        .foregroundColor(.textSecondary)

                                    if let exchange = result.exchange {
                                        Text(exchange)
                                            .font(.caption)
                                            .foregroundColor(.textTertiary)
                                    }
                                }
                            }
                        }
                    }

                    // Selected Stock
                    if let stock = viewModel.selectedStock {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(stock.symbol)
                                    .font(.headline)
                                Text(stock.name)
                                    .font(.subheadline)
                                    .foregroundColor(.textSecondary)
                            }
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .accessibilityHidden(true)
                        }
                        .padding(.vertical, 4)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Selected stock: \(stock.symbol), \(stock.name)")
                    }
                } header: {
                    Text("Stock")
                } footer: {
                    if let message = viewModel.validationMessage, viewModel.selectedStock == nil {
                        Text(message)
                            .foregroundColor(.red)
                    }
                }

                // Lot Details Section
                if viewModel.selectedStock != nil {
                    Section {
                        // Shares
                        HStack {
                            Text("Shares")
                            Spacer()
                            TextField("0", text: $viewModel.shares)
                                .focused($focusedField, equals: .shares)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .onChange(of: viewModel.shares) { _, newValue in
                                    viewModel.shares = viewModel.formatNumber(newValue)
                                }
                        }

                        // Price Per Share
                        HStack {
                            Text("Price Per Share")
                            Spacer()
                            TextField("0.00", text: $viewModel.pricePerShare)
                                .focused($focusedField, equals: .price)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .onChange(of: viewModel.pricePerShare) { _, newValue in
                                    viewModel.pricePerShare = viewModel.formatNumber(newValue)
                                }
                        }

                        // Currency
                        Picker("Currency", selection: $viewModel.selectedCurrency) {
                            ForEach(Currency.allCases, id: \.self) { currency in
                                Text("\(currency.symbol) \(currency.rawValue)")
                                    .tag(currency)
                            }
                        }

                        // Purchase Date
                        DatePicker("Purchase Date",
                                   selection: $viewModel.purchaseDate,
                                   in: ...Date(),
                                   displayedComponents: .date)

                        // Total Cost (Read-only)
                        if viewModel.totalCost > 0 {
                            HStack {
                                Text("Total Cost")
                                    .fontWeight(.semibold)
                                Spacer()
                                Text(viewModel.formattedTotalCost)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.accentColor)
                            }
                        }
                    } header: {
                        Text("Lot Details")
                    } footer: {
                        if let message = viewModel.validationMessage, viewModel.selectedStock != nil {
                            Text(message)
                                .foregroundColor(.red)
                        }
                    }

                    // Notes Section
                    Section {
                        TextField("Optional notes...", text: $viewModel.notes, axis: .vertical)
                            .focused($focusedField, equals: .notes)
                            .lineLimit(3...6)
                    } header: {
                        Text("Notes (Optional)")
                    }
                }
            }
            .navigationTitle("Add Stock")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        Task {
                            let success = await viewModel.addStock()
                            if success {
                                HapticManager.notification(.success)
                                dismiss()
                            } else {
                                HapticManager.notification(.error)
                            }
                        }
                    }
                    .disabled(!viewModel.isFormValid || viewModel.isLoading)
                }

                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button("Done") {
                            focusedField = nil
                        }
                    }
                }
            }
            .loading(viewModel.isLoading)
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") {
                    viewModel.dismissError()
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
            .alert("Success", isPresented: $viewModel.showSuccess) {
                Button("OK") {
                    viewModel.dismissSuccess()
                    dismiss()
                }
            } message: {
                Text("Stock added successfully!")
            }
        }
    }
}

// MARK: - Preview
#Preview {
    AddStockView()
}

import SwiftUI

/// 始点Y・行幅・ステップ数を設定するシートUI。
struct RowSettingsView: View {
    @Binding var startY: CGFloat
    @Binding var rowHeight: CGFloat
    @Binding var stepCount: Int
    let onApply: () -> Void

    @FocusState private var focusedField: Field?

    private enum Field { case startY, rowHeight }

    private var isValid: Bool {
        rowHeight > 0 && startY >= 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("行の位置") {
                    LabeledContent("始点 Y") {
                        TextField("例: 100", value: $startY, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .focused($focusedField, equals: .startY)
                    }
                    LabeledContent("行幅") {
                        TextField("例: 40", value: $rowHeight, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .focused($focusedField, equals: .rowHeight)
                    }
                }

                Section("進み方") {
                    Stepper("ステップ数：\(stepCount)", value: $stepCount, in: 1...20)
                }

                Section {
                    Button("適用") {
                        focusedField = nil
                        onApply()
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(!isValid)
                }
            }
            .navigationTitle("行の設定")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
    }
}

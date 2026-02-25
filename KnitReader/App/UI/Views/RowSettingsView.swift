import SwiftUI

/// 始点Y・行幅・ステップ数を設定するシートUI。
struct RowSettingsView: View {
    @Binding var startY: CGFloat
    @Binding var rowHeight: CGFloat
    @Binding var stepCount: Int
    let onApply: () -> Void

    @FocusState private var focusedField: Field?

    private enum Field { case startY, rowHeight }

    private var rowHeightError: String? {
        rowHeight <= 0 ? "行幅は 0 より大きい値を入力してください" : nil
    }

    private var startYError: String? {
        startY < 0 ? "始点 Y は 0 以上の値を入力してください" : nil
    }

    private var isValid: Bool {
        rowHeightError == nil && startYError == nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("始点 Y") {
                        TextField("例: 100", value: $startY, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .focused($focusedField, equals: .startY)
                    }
                    if let error = startYError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .accessibilityLabel("エラー: \(error)")
                    }
                    LabeledContent("行幅") {
                        TextField("例: 40", value: $rowHeight, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .focused($focusedField, equals: .rowHeight)
                    }
                    if let error = rowHeightError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .accessibilityLabel("エラー: \(error)")
                    }
                } header: {
                    Text("行の位置")
                } footer: {
                    Text("ドキュメント座標（ピクセル）で指定します。")
                }

                Section("進み方") {
                    Stepper("ステップ数：\(stepCount)", value: $stepCount, in: 1...20)
                        .accessibilityLabel("ステップ数 \(stepCount)")
                        .accessibilityHint("1 から 20 の間で設定します")
                }

                Section {
                    Button("適用") {
                        focusedField = nil
                        onApply()
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(!isValid)
                    .accessibilityLabel("設定を適用する")
                    .accessibilityHint(isValid ? "タップするとマーカーが再生成されます" : "入力値を修正してください")
                }
            }
            .navigationTitle("行の設定")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
    }
}

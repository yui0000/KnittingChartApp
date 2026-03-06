import SwiftUI

/// アプリの基本操作を説明するヘルプシート。
struct HelpView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("編み図を開く") {
                    HelpRow(
                        icon: "folder.badge.plus",
                        title: "ファイルを開く",
                        description: "右上のフォルダアイコンから画像（PNG / JPEG）または PDF を読み込みます。"
                    )
                }

                Section("行の設定") {
                    HelpRow(
                        icon: "slider.horizontal.3",
                        title: "行の設定を開始",
                        description: "左上のスライダーアイコンをタップして行設定モードに入ります。"
                    )
                    HelpRow(
                        icon: "hand.draw",
                        title: "ステップ1: 開始と幅を設定",
                        description: "ドラッグで最下行の位置を、ピンチで行幅を調整します。「次へ」で次のステップへ進みます。"
                    )
                    HelpRow(
                        icon: "hand.point.up",
                        title: "ステップ2: 終了位置を設定",
                        description: "開始位置より上の行をタップして最上行を指定します。「完了」で設定を反映します。"
                    )
                    HelpRow(
                        icon: "xmark.circle",
                        iconColor: .secondary,
                        title: "キャンセル",
                        description: "各ステップの「キャンセル」をタップすると設定前の状態に戻ります。"
                    )
                }

                Section("行を進める / 戻る") {
                    HelpRow(
                        icon: "plus.circle.fill",
                        title: "次の行に進む（Return）",
                        description: "現在行をチェック済みにして1行上へ進みます。チェックカウントも +1 されます。"
                    )
                    HelpRow(
                        icon: "minus.circle.fill",
                        iconColor: .secondary,
                        title: "1行戻る",
                        description: "1行下に戻り、戻った行のチェックを外します。チェックカウントも −1 されます。"
                    )
                }

                Section("リセット") {
                    HelpRow(
                        icon: "arrow.counterclockwise.circle",
                        title: "リセット",
                        description: "リセットボタンをタップすると選択肢が表示されます。"
                    )
                    HelpRow(
                        icon: "arrow.counterclockwise",
                        title: "すべて",
                        description: "チェック・行位置・カウントをすべて初期状態に戻します。"
                    )
                    HelpRow(
                        icon: "arrow.counterclockwise",
                        iconColor: .secondary,
                        title: "行位置のみ",
                        description: "チェックと行位置を初期状態に戻します。カウントは保持されます。"
                    )
                }

                Section("手書きメモ") {
                    HelpRow(
                        icon: "pencil.tip",
                        title: "手書きモード（⌘P）",
                        description: "鉛筆アイコンをタップして手書きモードをオンにします。Apple Pencil または指で書き込めます。「完了」で終了します。"
                    )
                    HelpRow(
                        icon: "trash",
                        title: "メモをクリア",
                        description: "ゴミ箱アイコンで手書きメモをすべて消去します。"
                    )
                }

                Section("行マーカーの見方") {
                    HelpRow(
                        icon: "rectangle.fill",
                        iconColor: .yellow.opacity(0.5),
                        title: "現在行（黄色バンド）",
                        description: "今読んでいる行を黄色い帯でハイライト表示します。"
                    )
                    HelpRow(
                        icon: "checkmark.square.fill",
                        iconColor: .yellow,
                        title: "チェック済み",
                        description: "読み終えた行のチェックボックスが塗りつぶされます。チェックの操作は＋／−ボタンで行います。"
                    )
                    HelpRow(
                        icon: "square",
                        iconColor: .yellow.opacity(0.6),
                        title: "未チェック",
                        description: "まだ読んでいない行は空のチェックボックスで表示されます。"
                    )
                }

                Section("キーボードショートカット") {
                    HelpRow(icon: "keyboard", title: "Return", description: "次の行に進む（＋ボタンと同じ）")
                    HelpRow(icon: "keyboard", title: "⌘P", description: "手書きモードのオン / オフ")
                }
            }
            .navigationTitle("ヘルプ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }
}

// MARK: - HelpRow

private struct HelpRow: View {
    let icon: String
    var iconColor: Color = .accentColor
    let title: String
    let description: String

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: icon)
                .foregroundStyle(iconColor)
                .frame(width: 24)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title)。\(description)")
    }
}

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
                        title: "読み込み元を選択",
                        description: "右上のフォルダアイコンをタップすると「ファイルから」「写真から」の選択肢が表示されます。"
                    )
                    HelpRow(
                        icon: "doc.badge.plus",
                        title: "ファイルから",
                        description: "Files アプリから画像（PNG / JPEG / HEIC）または PDF を読み込みます。"
                    )
                    HelpRow(
                        icon: "photo",
                        title: "写真から",
                        description: "写真ライブラリから画像を選択して読み込みます。"
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

                Section("画面の見方") {
                    HelpRow(
                        icon: "number",
                        title: "行番号（左）",
                        description: "画面上部に「行 X / Y」形式で現在行番号を表示します。X は下から数えた現在の行、Y は総行数です。"
                    )
                    HelpRow(
                        icon: "checkmark.circle",
                        title: "チェックカウント（右）",
                        description: "画面上部の数字は、これまで進めた行の総カウントです。リセットするまで累積されます。"
                    )
                }

                Section("行を進める / 戻る") {
                    HelpRow(
                        icon: "plus.circle.fill",
                        title: "次の行に進む",
                        description: "画面下中央の＋ボタンをタップします。現在行をチェック済みにして1行上へ進みます。チェックカウントも +1 されます。"
                    )
                    HelpRow(
                        icon: "minus.circle.fill",
                        iconColor: .secondary,
                        title: "1行戻る",
                        description: "画面下中央の−ボタンをタップします。1行下に戻り、戻った行のチェックを外します。チェックカウントも −1 されます。"
                    )
                }

                Section("リセット") {
                    HelpRow(
                        icon: "arrow.counterclockwise.circle",
                        title: "リセット",
                        description: "右下のリセットボタンをタップすると選択肢が表示されます。"
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
                    HelpRow(
                        icon: "pencil.tip",
                        iconColor: .secondary,
                        title: "手書きメモ",
                        description: "手書きメモのみを消去します。行位置・カウントは保持されます。"
                    )
                }

                Section("手書きメモ") {
                    HelpRow(
                        icon: "pencil.tip",
                        title: "手書きモード",
                        description: "左下の鉛筆アイコンをタップして手書きモードをオンにします。Apple Pencil または指で書き込めます。「完了」で終了します。"
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

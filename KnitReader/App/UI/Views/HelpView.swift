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

                Section("行を進める") {
                    HelpRow(
                        icon: "plus.circle.fill",
                        title: "次の行に進む",
                        description: "＋ボタンまたは Return キーで現在行を進めます。前の行がチェック済みになります。"
                    )
                    HelpRow(
                        icon: "slider.horizontal.3",
                        title: "行の設定",
                        description: "始点 Y・行幅・ステップ数を変更します。適用するとマーカーが再生成されます。"
                    )
                    HelpRow(
                        icon: "arrow.uturn.backward",
                        title: "元に戻す",
                        description: "行インデックス・マーカー・チェックカウントをそれぞれ独立して元に戻せます。"
                    )
                }

                Section("手書きメモ") {
                    HelpRow(
                        icon: "pencil.tip",
                        title: "手書きモード（⌘P）",
                        description: "鉛筆アイコンをタップして手書きモードをオンにします。Apple Pencil または指で書き込めます。"
                    )
                    HelpRow(
                        icon: "trash",
                        title: "メモをクリア",
                        description: "ゴミ箱アイコンで手書きメモをすべて消去します。"
                    )
                }

                Section("行マーカーの見方") {
                    HelpRow(
                        icon: "minus",
                        iconColor: .accentColor,
                        title: "現在行（太い実線）",
                        description: "今読んでいる行を示します。"
                    )
                    HelpRow(
                        icon: "minus",
                        iconColor: .secondary,
                        title: "チェック済み（細い実線）",
                        description: "完了済みの行です。"
                    )
                    HelpRow(
                        icon: "ellipsis",
                        iconColor: .secondary.opacity(0.5),
                        title: "未チェック（点線）",
                        description: "まだ読んでいない行です。"
                    )
                }

                Section("キーボードショートカット") {
                    HelpRow(icon: "keyboard", title: "Return", description: "次の行に進む")
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

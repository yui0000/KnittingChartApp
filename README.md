# KnitReader — 編み図読み取りアプリ（iOS / SwiftUI）

PDF・画像の編み図を読み込み、**ズーム/パン**しながら、**行マーカー**・**チェック**・**カウント**で進捗管理できるネイティブアプリです。  
**PencilKit** による手書きメモ、**記号検索 & ピン留め**もサポート。座標は **ドキュメント座標系** で一貫管理し、描画時に投影します。

## ✨ 主な機能（MVP → 拡張）
- [x] PDF/画像の読み込みと表示（ズーム/パン）
- [x] 行マーカー：**始点Y**・**行幅**・**step** 設定、＋で移動
- [x] ☑ とカウント：＋操作時に**チェック追加** & **カウントUP**
- [x] **戻す**：☑／マーカー／カウントを**独立**してUndo
- [x] ズーム/パンに合わせて**オーバーレイ追従**
- [ ] PencilKit 手書きメモ（保存/復元）
- [ ] 記号辞書の検索 & ピン留め（最大5）
- [ ] PDF複数ページ対応、iCloud同期 など

## 🏗 アーキテクチャ
- **UI**: SwiftUI（iOS 17+）
- **描画/入出力**: PDFKit, UIScrollViewブリッジ, PencilKit
- **座標系**: すべて**ドキュメント座標**で保持、表示時に `CGAffineTransform` で投影
- **永続化**: SwiftData（iOS 17+）
- **設計**: MVVM + Clean（Domain / Data / UI / Kit）

```
/App
  /Domain        # UseCase, Entity, Repository protocol
  /Data          # Repository実装, SwiftDataモデル
  /UI            # SwiftUI Views, ViewModels
  /Kit           # PDFKit/PencilKit/ScrollViewブリッジ, 座標変換
  /Resources     # assets, symbols.json
  /Tests         # 単体テスト
```

## ⚙️ 前提
- macOS + Xcode（最新版推奨）
- VS Code（任意）＋ Claude Code 拡張（任意だが推奨）
- iOS 17+ ターゲット

> **補足**：編集は VS Code、ビルド/実行は Xcode（CLI含む）運用が現実的です。

## 🚀 セットアップ & 実行
### 1) 依存の準備
- Xcode をインストール
- 初回のみ Xcode でプロジェクトを開き、`Signing & Capabilities` の **Team** を設定（自動署名ON推奨）

### 2) コマンドラインでビルド/実行（例）
```bash
# シミュレータ一覧
xcrun simctl list devices

# ビルド
xcodebuild   -project KnitReader.xcodeproj   -scheme KnitReader   -configuration Debug   -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest'   build

# シミュレータにインストール & 起動
xcrun simctl boot 'iPhone 15' || true
xcrun simctl install booted ./Build/Products/Debug-iphonesimulator/KnitReader.app
xcrun simctl launch booted com.example.KnitReader
```

### 3) テスト
```bash
xcodebuild   -project KnitReader.xcodeproj   -scheme KnitReader   -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest'   test
```

## 🧪 開発ガイド（Claude Code の利用）
- 仕様・プロンプト集は **`docs/claude-prompts.md`** を参照  
- Claude には**差分パッチ**形式での出力を依頼し、  
  「変更ファイル一覧 / ファイル内容 / 実行手順 / 注意点」を必ず含める運用とします

## 🎨 UX/アクセシビリティ方針
- 色弱対応（配色プリセット）
- Dynamic Type / VoiceOver ラベル設計
- キーボードショートカット（行移動・戻す・チェック切替）

## 🧭 コーディング規約（抜粋）
- 座標は**常にドキュメント座標**で保管（UI座標は描画時のみ）
- View の肥大化を避け、ロジックは ViewModel / UseCase に寄せる
- 例外時はユーザー行動の回復手段を提示（リトライ/再選択）

## 🗺️ ロードマップ（例）
- M1: 画像対応MVP（行設定/＋/独立Undo/ズーム追従）
- M2: PencilKit メモ（保存/復元）
- M3: 記号辞書・検索・ピン留め
- M4: PDF複数ページ・共有拡張・iCloud同期

## 📄 ライセンス
- LICENSE を追記してください（MIT など）

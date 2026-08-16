# Re:Body

忙しい人が、娯楽や休息の前に2〜15分だけ身体を更新し、魅力と能力を回復・向上させるiOSネイティブアプリです。プロジェクト名はFutureBodyです。

## 現在の範囲

- プロダクトインサイトと設計原則: [`docs/PRODUCT_INSIGHTS.md`](../docs/PRODUCT_INSIGHTS.md)
- SwiftUI / iOS 17+
- LINE Seed JPフォント
- 今日の状態確認
- お腹・見た目 / 胸・腕の厚み / 動く・支える / 全体を底上げの目的別メニュー
- 2分の起動・10分の土台づくり・15分の伸ばす時間
- 中断後の再開導線
- ローカルの完了記録
- 20:50の通知設定
- 未来シナリオのフォールバック表示
- 記録画面
- 仲間機能の導線
- Firebase Authentication / Firestoreへの匿名同期

## Firebase設定

Firebase設定ファイルは公開リポジトリに含めません。Firebase ConsoleからiOSアプリ用の`GoogleService-Info.plist`をダウンロードし、`FutureBody/GoogleService-Info.plist`に置いてください。ファイルがない場合もアプリは端末内保存で起動できます。

本番ビルドでは、存在する設定ファイルをビルド時にアプリへコピーします。Firestore Rulesでユーザー自身の匿名アカウント以外からの読み書きを拒否しています。

## 次の段階

- Core MLによる本人写真の未来画像
- Family Controls / Device Activity
- Sign in with Apple
- 仲間機能の実装
- 実験イベントのリモート収集

## 安全に関する注意

本アプリは医療行為や診断を行うものではありません。痛みがある場合、または運動中に痛みや強い違和感が出た場合は中止し、必要に応じて医療専門家へ相談してください。

## フォント

LINE Seed JPを使用しています。フォントはLINE Seed公式ページから取得し、SIL Open Font License 1.1に従います。

https://seed.line.me/index_jp.html

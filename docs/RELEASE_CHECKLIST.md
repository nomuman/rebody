# Re:Body リリースチェックリスト

## 現在の状態

- App Store Connectへアップロード済みのBuild 8：Firebase復元とiPhone内AIコーチ導線を含む過去ビルド
- App Store Connectへアップロード済みのBuild 9：未使用の仲間タブを初回リリースから外し、削除ルールを補強した過去ビルド
- App Store Connectへアップロード済みのBuild 12：ホーム画面から時間をすぐ選べるようにし、見出しを整理したビルド。現在はApp Store Connectで処理中

## 完了済み

- SwiftUIアプリ本体、アイコン、LINE Seed JPフォント
- iOS 17.0以上の設定
- Firebase Authentication匿名ログインとFirestore同期
- Firestore Rulesの公開
- プライバシーポリシーとサポートページの公開
- Privacy Manifestの追加（匿名アカウントに紐づく同期データを正確に申告）
- アプリ内のアカウント・データ削除
- 痛みがある場合の休止導線と安全上の注意
- 13件のユニットテスト
- OUR ENGINEERING（W7WQFW7K74）向けStore署名とアップロード
- App Store掲載文案と審査メモ
- 実際のアプリ画面から作成した6.3インチ・6.9インチ用スクリーンショット
- GitHub公開リポジトリの秘密情報スキャン

## App Store Connectで必要な作業

1. XcodeのSettings → Accountsで、OUR ENGINEERINGにアクセスできるApple Accountへログインする（完了）
2. `app.futurebody.mobile`のTeamがOUR ENGINEERINGになっていることを確認する（完了）
3. App Store Connectで、アプリ名、説明、キーワード、カテゴリ、年齢レーティング、プライバシー回答、スクリーンショットを登録する
4. App Informationで、規制対象医療機器を「いいえ」と回答し、DSAの質問が表示された場合は運営者情報に基づいて回答する
5. Build 12の処理完了後、輸出コンプライアンスを確認してTestFlightで内部テストを行う
6. 審査情報を入力し、「Add for Review」→「Submit for Review」を実行する

## IPA作成とアップロード

再アップロードが必要になった場合は、リポジトリのルートで次を実行します。

```sh
Scripts/release_app_store.sh
```

このスクリプトは、Xcodeに登録したApple Accountの自動署名を使ってアーカイブし、App Store Connectへ直接アップロードします。IPAだけを作る場合は、次のように実行します。

```sh
EXPORT_DESTINATION=export Scripts/release_app_store.sh
```

App Store Connect APIキーを使ってアップロードする場合は、標準のAPIキー配置に秘密鍵を置き、次のように実行します。

```sh
ASC_API_KEY_ID=XXXX ASC_ISSUER_ID=XXXX Scripts/release_app_store.sh
```

## 公開URL

- プライバシーポリシー：https://future-body-app-20260816.web.app/privacy
- サポート：https://future-body-app-20260816.web.app/support
- マーケティングURL：https://future-body-app-20260816.web.app/

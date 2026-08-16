# Re:Body リリースチェックリスト

## 現在の状態

- App Store Connectへの提出候補Build 5：アップロード完了
- Build 5のApp Store Connect処理状態：画面で確認が必要

## 完了済み

- SwiftUIアプリ本体、アイコン、LINE Seed JPフォント
- iOS 17.0以上の設定
- Firebase Authentication匿名ログインとFirestore同期
- Firestore Rulesの公開
- プライバシーポリシーとサポートページの公開
- Privacy Manifestの追加
- アプリ内のアカウント・データ削除
- 痛みがある場合の休止導線と安全上の注意
- 8件のユニットテスト
- OUR ENGINEERING（W7WQFW7K74）向けStore署名とアップロード
- App Store掲載文案と審査メモ
- GitHub公開リポジトリの秘密情報スキャン

## App Store Connectで必要な作業

1. XcodeのSettings → Accountsで、OUR ENGINEERINGにアクセスできるApple Accountへログインする（完了）
2. `app.futurebody.mobile`のTeamがOUR ENGINEERINGになっていることを確認する（完了）
3. App Store Connectで、アプリ名、説明、キーワード、カテゴリ、年齢レーティング、プライバシー回答、スクリーンショットを登録する
4. Build 5の処理が完了したら、TestFlightで内部テストを行う
5. 審査情報を入力し、「審査に提出」を実行する

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

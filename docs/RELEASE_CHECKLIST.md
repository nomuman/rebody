# Re:Body リリースチェックリスト

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
- OUR ENGINEERING（W7WQFW7K74）向け開発アーカイブ
- App Store掲載文案と審査メモ
- GitHub公開リポジトリの秘密情報スキャン

## Apple側で一度だけ必要な作業

1. XcodeのSettings → Accountsで、OUR ENGINEERINGにアクセスできるApple Accountへログインする
2. Manage CertificatesからApple Distribution証明書を追加する
3. `app.futurebody.mobile`のTeamがOUR ENGINEERINGになっていることを確認する
4. App Store Connectで、アプリ名、説明、キーワード、カテゴリ、年齢レーティング、プライバシー回答、スクリーンショットを登録する

## IPA作成とアップロード

証明書が入った後、リポジトリのルートで次を実行します。

```sh
Scripts/release_app_store.sh
```

IPAだけを作る場合は、`ASC_API_KEY_ID`と`ASC_ISSUER_ID`を設定せずに実行します。App Store Connect APIキーを使ってアップロードする場合は、標準のAPIキー配置に秘密鍵を置き、次のように実行します。

```sh
ASC_API_KEY_ID=XXXX ASC_ISSUER_ID=XXXX Scripts/release_app_store.sh
```

## 公開URL

- プライバシーポリシー：https://future-body-app-20260816.web.app/privacy
- サポート：https://future-body-app-20260816.web.app/support
- マーケティングURL：https://future-body-app-20260816.web.app/

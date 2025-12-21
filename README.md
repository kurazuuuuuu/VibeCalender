# ハックツハッカソン 〜プテラカップ〜
## [ハッカソンDoorkeeper](https://hackz-community.doorkeeper.jp/events/191089)

## Githubリポジトリ
* iOSアプリ：https://github.com/kurazuuuuuu/VibeCalender (カレンダーtypoしてます)
* バックエンド：https://github.com/kurazuuuuuu/ptera-cup-2025

## 概要
* 「4年に1度」--> 「日時」-->**「カレンダー」**
* シンプルなLiquid Glass対応のカレンダーアプリ。SNSの機能もあります。すごいね。
* メモアプリとしても使用することができ非常に有能。

> [!WARNING]
> 勝手にメモから個人データを学習されます。
> 学習されたデータを使ってAIが勝手に予定を作ってくれます。
> 生成された予定は勝手にタイムラインに投稿されます。予定をすっぽかすことはできません。*監視されます。*
> **でも大丈夫。生成される予定は匿名性が高いため身バレの心配はありません。**

> [!NOTE]
> クリスマスに予定がないであろう **あなたも** これで*予定があると言い張ることができます。*

---

> [!Tip]
> 1. ローカルでAIが動くためプライバシーの心配はありません。サーバーが扱うのはログイン・タイムラインのデータのみです。
> 2. iOS標準カレンダーにアクセスするため普段と変わらず予定を管理できます。<br>（なお手動で予定を挿入する機能は存在しません。）

## 技術スタック
### フロントエンド
* Swift
    * SwiftUI
    * Liquid Glass UI (Only over iOS26)
    * Foundation Model Framework (Local LLM)

### バックエンド
* Python
    * FastAPI

### 開発環境
#### > CloudIDE
* Coder (krz-tech-homelab)
    * Docker Container
    * vscode-web

#### > Environment & Package Management
* Docker
* Gem

#### > IDE
* XCode (MacOS 26)
* VSCode
* Antigravity
    * Gemini, Claude Opus, etc...

## 開発
### メンバー
* Swift 2人 (内1人インフラ)
    * @kurazuuuuuu
    * @KYPark222
* バックエンド 2人
    * @sei0426
    * @akira-68
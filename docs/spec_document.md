アプリケーション仕様書 (localTodo)
1. 概要
localTodo は、GTD (Getting Things Done) メソッドに基づいたタスク管理アプリケーションです。Flutterで構築されており、ローカルデータベースを使用したオフラインファーストな設計となっています。ユーザーはタスクの収集、整理、実行、レビューを効率的に行うことができます。

2. データモデル
2.1 Todo (タスク)
タスクは以下の属性を持ちます。

- ID: 一意の識別子
- Parent ID: 親タスクのID（サブタスクの場合）
- Title: タスクのタイトル
- Category (GTDカテゴリ):
  - Inbox: 未処理のタスク
  - Next Action: 次にやるべき行動
  - Project: 複数のステップを要するタスク
  - Waiting For: 他者待ち
  - Someday/Maybe: いつかやる/多分やる
  - Reference: 資料
- Is Done: 完了フラグ
- Priority (優先度): High (高), Medium (中), Low (低), None (なし)
- Due Date: 期限日
- Tags: タグ（リスト）
- Note: メモ
- URL: 関連URL
- Repeat Pattern (繰り返し):
  - None, Daily, Weekly, Monthly, Yearly
- Subtasks: サブタスクのリスト
- Delegatee: 担当者（委任先）
- Delegated Date: 委任日
- Last Completed Date: 最終完了日（繰り返しタスク用）

3. 機能一覧
3.1 タスク管理
- 作成: Floating Action Button または Quick Add ウィジェットからタスクを追加可能。デフォルトは Inbox カテゴリ。
- 編集: タスクの詳細（タイトル、期限、優先度、メモ、サブタスクなど）を編集可能。
- 完了/未完了切り替え: チェックボックスでステータスを変更。繰り返しタスクの場合、完了すると次の期日のタスクが自動作成される。
- 削除: 不要なタスクを削除可能。
- サブタスク: タスク内にサブタスクを作成可能。サブタスクを独立したタスクに「昇格」させる機能あり。

3.2 ビュー (表示モード)
メイン画面では SegmentedButton により以下の切り口でタスクを表示可能。

- カテゴリ: GTDカテゴリごとにグループ化
- 優先度: 優先度（高、中、低）ごとにグループ化
- 期限日: 期日ごとにグループ化
- コンテキスト: タグ（@Context）ごとにグループ化
- 委任: 担当者ごとにグループ化（「待ち」タスク用）

3.3 特別なビュー・機能
- Daily Standup (今日の予定):
  - Blockers (期限切れ/高優先度), Today's Plan (今日やるべきこと), Yesterday's Wins (昨日の成果) を表示。
- クリップボードへのサマリコピー機能。
- CustomScrollView による高速な描画。
- Project Portfolio: プロジェクト（親タスク）ごとの進捗確認ダッシュボード。
- Inbox Zero (処理): Inboxにあるタスクを次々と処理（分類・削除・完了）するための専用モード。
- 週次レビュー: ウィザード形式で週ごとの振り返りと整理を行う機能。

3.4 設定
- テーマ切り替え: ライトモード、ダークモード、システム設定に従う。
- データ管理: CSVインポート機能。

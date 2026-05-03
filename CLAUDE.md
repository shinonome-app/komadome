# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## プロジェクト概要
Komadomeは、同じコンテンツを静的・動的ページの両方で生成するRuby on Railsアプリケーションです。

## 開発コマンド

### セットアップ・起動
```bash
# 初期セットアップ
bin/setup

# 開発サーバー起動
bin/dev
```

### ビルド
```bash
# 全ページの静的ビルド
bin/rails build:all

# 特定のタスクのビルド
bin/rails build:generate_indexes    # インデックスページ
bin/rails build:generate_work       # 作品ページ
bin/rails build:generate_person     # 人物ページ
```

### テスト・リント
```bash
# RSpecテスト実行
bin/rails spec

# 単体テスト実行
bin/rails spec spec/path/to/test_spec.rb

# Rubocop実行
bin/rubocop

# ERBLint実行
bin/rails erb_lint
```

### 型チェック・品質
```bash
# Rubocop自動修正
bin/rubocop -a

# ERBLint自動修正
bin/rails erb_lint --fix
```

## アーキテクチャ

### 主要技術スタック
- **Ruby on Rails 8.0.1** (Ruby 3.4.2)
- **ViewComponent** - `app/views`ディレクトリを使わず、すべてのページテンプレートを`app/components/pages`に配置
- **Tailwind CSS** - Node.jsを使わないスタンドアロン構成
- **PostgreSQL** - データベース
- **RSpec** - テスト
- **Rubocop** - リンター

### ディレクトリ構造
- `app/components/` - ViewComponentベースのコンポーネント
  - `pages/` - ページレベルのコンポーネント
  - `layout_component.*` - レイアウトコンポーネント
- `app/lib/` - アプリケーション固有のライブラリ
  - `static_page_builder.rb` - 静的ページ生成
  - `kana.rb` - かな文字処理
- `lib/tasks/build.rake` - ビルドタスク定義
- `build/` - 生成された静的ファイル

### 静的・動的ページシステム
- **動的ページ**: Port 4000でRails (Puma)サーバーによる配信
- **静的ページ**: Port 8000でWEBrickによる配信
- **StaticPageBuilder**: 静的ページ生成を担当するクラス

### コンポーネント構造
- ページテンプレート: `app/components/pages/[controller]/[action]_page_component.html.erb`
- 対応するRubyクラス: `app/components/pages/[controller]/[action]_page_component.rb`
- レイアウト: `app/components/layout_component.html.erb`

例：`cards#show`のページは
- `app/components/pages/cards/show_page_component.html.erb`
- `app/components/pages/cards/show_page_component.rb`

### 多言語対応
- デフォルトロケール: 日本語 (ja)
- タイムゾーン: Asia/Tokyo

### 環境変数
- `MAIN_SITE_URL` - メインサイトURL
- `SITE_NAME` - サイト名（Unicode文字列対応）
- `CSV_DIR` - CSVファイルディレクトリ
- `RECEPTION_EMAIL` - 受付メールアドレス

## 開発のポイント

### ViewComponentの使用
- 従来のERBビューファイルは使用せず、ViewComponentを使用
- `app/components/pages/`以下にページコンポーネントを配置

### クエリ層
- 基本は ActiveRecord を view / controller から素直に呼び出す
- 共通化したいクエリは Person / Work model の scope や class method に集約 (例: `Person.with_name_firstchar(kana)`、`Person.with_unpublished_works_by_kana(kana)`)。Shinonome へコピーされる前提で受け入れる
- view から `where(...).order(...)` のような長いチェーンを直接書くのは避け、model 側に名前付きで集約する

### 静的ページ生成
- `StaticPageBuilder`クラスを使用して静的ページを生成
- `build/`ディレクトリに出力される

### かな文字処理
- `Kana`クラスで日本語文字の処理を実装
- 作品の頭文字による分類機能

### デプロイ
- Kamalを使用した本番環境デプロイ
- rsyncによる静的ファイル同期機能
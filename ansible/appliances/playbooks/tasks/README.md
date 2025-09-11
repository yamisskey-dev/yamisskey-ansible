# Appliance Playbook Tasks

このディレクトリには、アプライアンス（TrueNAS）向けプレイブックで使用される共通タスクが含まれています。

## 📁 ディレクトリ構造

```
tasks/
└── migrate/                    # MinIO移行関連タスク
    ├── 00_preamble.yml        # 移行前準備・事前チェック
    ├── 05_preflight.yml       # プリフライトチェック
    ├── 40_final_mirror.yml    # 最終同期・ミラーリング
    ├── 50_iam_and_cors.yml    # IAM・CORS設定
    └── 90_verify_and_cleanup.yml # 検証・クリーンアップ
```

## 🔄 MinIO移行タスク詳細

### フェーズ別タスク構成

#### 00_preamble.yml - 移行前準備
- **目的**: 移行プロセスの初期化
- **実行内容**:
  - 移行環境の整合性チェック
  - 必要な権限・設定の確認
  - ログ・作業ディレクトリの準備
- **実行タイミング**: 移行開始時

#### 05_preflight.yml - プリフライトチェック
- **目的**: 移行実行前の安全性確認
- **実行内容**:
  - ソース・デスティネーション接続性確認
  - ストレージ容量・スペース確認
  - サービス稼働状況チェック
- **実行タイミング**: データ移行前

#### 40_final_mirror.yml - 最終同期
- **目的**: 本格的なデータミラーリング
- **実行内容**:
  - 増分同期・差分データ転送
  - チェックサム検証
  - 転送ログ・統計情報記録
- **実行タイミング**: メイン移行フェーズ

#### 50_iam_and_cors.yml - 設定移行
- **目的**: アクセス制御・セキュリティ設定の移行
- **実行内容**:
  - IAMポリシー・ユーザー設定移行
  - CORS設定の複製
  - バケットポリシーの適用
- **実行タイミング**: データ移行後

#### 90_verify_and_cleanup.yml - 検証・後処理
- **目的**: 移行完了後の検証とクリーンアップ
- **実行内容**:
  - データ整合性検証
  - 移行ログ・レポート生成
  - 一時ファイル・設定のクリーンアップ
- **実行タイミング**: 移行プロセス最終段階

## 🚀 使用方法

### 個別タスク実行
```bash
# 特定のタスクファイルを含むプレイブック実行
make run PLAYBOOK=migrate-minio-phase-a TARGET=appliances

# プリフライトチェックのみ
make run PLAYBOOK=migrate-minio-phase-a TARGET=appliances TAGS=preflight

# 最終同期のみ
make run PLAYBOOK=migrate-minio-phase-a TARGET=appliances TAGS=mirror
```

### フルフロー実行
```bash
# 完全移行シーケンス
make deploy PLAYBOOKS='migrate-minio-phase-a migrate-minio-truenas migrate-minio-cutover' TARGET=appliances
```

## ⚙️ タスク設計パターン

### 共通構造
```yaml
---
- name: Task group description
  block:
    - name: Individual task
      uri:
        url: "{{ truenas_base_url }}/api/v2.0/endpoint"
        method: GET/POST/PUT
        headers:
          Authorization: "Bearer {{ api_key }}"
        body_format: json
        body: "{{ task_specific_data }}"
      register: task_result
      
    - name: Validate result
      assert:
        that:
          - task_result.status == 200
        fail_msg: "Task failed: {{ task_result.msg }}"
```

### エラーハンドリング
```yaml
- name: Task with error handling
  uri:
    # ... uri configuration
  register: api_result
  failed_when: false
  
- name: Handle API errors
  fail:
    msg: "API call failed: {{ api_result.json.message }}"
  when: 
    - api_result.status != 200
    - api_result.json is defined
```

## 🔧 開発ガイドライン

### タスク作成原則
1. **冪等性**: 複数回実行しても同じ結果
2. **原子性**: 各タスクは独立して完結
3. **検証**: 実行結果の必須確認
4. **ログ**: 十分なデバッグ情報出力

### 変数命名規則
```yaml
# TrueNAS API関連
truenas_base_url: "https://truenas.local"
api_key: "{{ vault_truenas_api_key }}"

# 移行関連
migration_source_endpoint: "source-minio.example.com"
migration_dest_endpoint: "dest-minio.example.com"
migration_bucket_list: ["files", "media", "backup"]

# タスク固有
preflight_check_timeout: 300
mirror_sync_retries: 3
verify_checksum_enabled: true
```

## 📊 実行フロー例

### 移行プロセス全体
```
1. Preamble (00_preamble.yml)
   ├── 環境初期化
   ├── ログ設定
   └── 作業ディレクトリ準備

2. Preflight (05_preflight.yml)  
   ├── 接続性チェック
   ├── 容量チェック
   └── 依存関係確認

3. Final Mirror (40_final_mirror.yml)
   ├── データ同期開始
   ├── 進捗監視
   └── 整合性確認

4. IAM and CORS (50_iam_and_cors.yml)
   ├── ポリシー移行
   ├── ユーザー設定移行
   └── CORS設定適用

5. Verify and Cleanup (90_verify_and_cleanup.yml)
   ├── 最終検証
   ├── レポート生成
   └── クリーンアップ
```

## 🔗 関連ドキュメント

- [**アプライアンスロール**](../../roles/README.md) - TrueNASロール全般
- [**アプライアンス概要**](../../README.md) - アプライアンス管理全般
- [**MinIO移行ガイド**](../migrate-minio-phase-a.yml) - 具体的な移行プレイブック
- [**プロジェクト全体**](../../../../README.md) - 全体概要

## 🐛 トラブルシューティング

### よくある問題

#### API接続エラー
```bash
# TrueNAS API接続確認
curl -k -H "Authorization: Bearer $API_KEY" \
  https://truenas.local/api/v2.0/system/info

# 接続設定確認
cat ansible/appliances/group_vars/all.yml | grep truenas_base_url
```

#### 権限エラー
```bash
# APIキーの権限確認
# TrueNAS Web UI > Account > API Keys で確認

# インベントリファイルの確認
cat ansible/appliances/inventory
```

#### タスク実行エラー
```bash
# 詳細ログでデバッグ実行
make run PLAYBOOK=migrate-minio-phase-a TARGET=appliances -vvv

# 特定タスクのみ実行
make run PLAYBOOK=migrate-minio-phase-a TARGET=appliances TAGS=preamble
# TrueNAS Appliance Playbooks

このディレクトリには、TrueNAS等のアプライアンス機器向けのAnsibleプレイブックが含まれています。主にMinIOの展開と移行に特化した設定を提供します。

## 📦 プレイブック一覧

### 1. setup.yml - 基本セットアップ
**目的**: TrueNASの基本設定とMinIO準備

**機能**:
- TrueNAS Core/Scale環境の設定確認
- 必要なデータセットとユーザー/グループ作成
- Docker互換環境準備
- ネットワーク設定

**使用方法**:
```bash
# 統一コマンド体系での実行
make run TARGET=appliances PLAYBOOK=setup

# 直接Ansible実行
ansible-playbook -i inventory playbooks/setup.yml
```

**前提条件**:
- TrueNAS Core 13.0+ または TrueNAS Scale 22.02+
- API アクセス有効化
- 適切なネットワーク設定

---

### 2. truenas-minio-deploy-and-migrate.yml - MinIO統合展開
**目的**: TrueNAS上でのMinIOサービス展開と既存データ移行

**機能**:
- MinIO Docker Composeサービス展開
- TrueNAS API経由でのデータセット管理
- 既存MinIOからの段階的データ移行
- IAMポリシー設定とCORS設定

**使用方法**:
```bash
# 完全な展開と移行
make run TARGET=appliances PLAYBOOK=truenas-minio-deploy-and-migrate

# ドライラン
make run TARGET=appliances PLAYBOOK=truenas-minio-deploy-and-migrate CHECK=true
```

**移行フェーズ**:
1. **プリフライト**: 環境検証
2. **ウォームアップ**: 初期データ同期
3. **最終ミラー**: 差分同期
4. **IAM・CORS**: 設定移行
5. **検証・クリーンアップ**: 完了確認

---

### 3. migrate-minio-phase-a.yml - MinIO移行 フェーズA
**目的**: MinIO移行の準備段階実行

**機能**:
- 移行前環境の検証
- エイリアス設定とバケット作成
- 初期データウォームアップ

**使用方法**:
```bash
# フェーズA実行
make run TARGET=appliances PLAYBOOK=migrate-minio-phase-a

# 特定タスクのみ
make run TARGET=appliances PLAYBOOK=migrate-minio-phase-a TAGS=preflight
```

---

### 4. migrate-minio-truenas.yml - TrueNAS特化移行
**目的**: TrueNAS環境特有の移行処理

**機能**:
- TrueNAS API統合
- ZFS データセット最適化
- スナップショット管理
- パフォーマンス最適化

**使用方法**:
```bash
# TrueNAS特化移行
make run TARGET=appliances PLAYBOOK=migrate-minio-truenas

# バックアップ付き実行
make run TARGET=appliances PLAYBOOK=migrate-minio-truenas EXTRA_VARS="backup_enabled=true"
```

---

### 5. migrate-minio-cutover.yml - 移行カットオーバー
**目的**: MinIO移行の最終カットオーバー処理

**機能**:
- 旧システム停止
- DNS切り替え
- 最終検証
- ロールバック手順

**使用方法**:
```bash
# カットオーバー実行
make run TARGET=appliances PLAYBOOK=migrate-minio-cutover

# ロールバック
make run TARGET=appliances PLAYBOOK=migrate-minio-cutover EXTRA_VARS="rollback=true"
```

## 🛠️ 高度な使用方法

### 環境別実行
```bash
# 本番TrueNAS
make run TARGET=appliances PLAYBOOK=setup LIMIT=truenas-prod

# 開発TrueNAS
make run TARGET=appliances PLAYBOOK=setup LIMIT=truenas-dev
```

### パラメータ化実行
```bash
# カスタムMinIOバージョン
make run TARGET=appliances PLAYBOOK=truenas-minio-deploy-and-migrate EXTRA_VARS="minio_version=RELEASE.2024-01-16T16-07-38Z"

# 移行ソース指定
make run TARGET=appliances PLAYBOOK=migrate-minio-phase-a EXTRA_VARS="source_endpoint=https://old-minio.example.com"
```

## 🔒 セキュリティ考慮事項

1. **TrueNAS API**: Root APIキーの安全な管理
2. **MinIO認証**: アクセスキーとシークレットキーの暗号化
3. **ネットワーク**: 適切なファイアウォール設定
4. **データ**: 転送中および保存時の暗号化

## 📊 移行処理フロー

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   setup.yml     │ -> │  phase-a.yml    │ -> │ truenas-xxx.yml │
│  基本セットアップ  │    │   準備フェーズ    │    │  TrueNAS統合   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                                        │
┌─────────────────┐    ┌─────────────────┐              │
│  cutover.yml    │ <- │deploy-and-xxx.yml│ <-----------┘
│  最終カットオーバー │    │   完全展開      │
└─────────────────┘    └─────────────────┘
```

## 🚨 トラブルシューティング

### よくある問題

**1. TrueNAS API接続エラー**
```bash
# API設定確認
curl -k -H "Authorization: Bearer $API_KEY" \
  https://truenas.local/api/v2.0/system/info

# APIキー再生成
```

**2. MinIO権限エラー**
```bash
# MinIOユーザー確認
mc admin user list myminio

# データセット権限確認
zfs allow
```

**3. 移行データ不整合**
```bash
# データ整合性チェック
make run TARGET=appliances PLAYBOOK=migrate-minio-phase-a TAGS=verify

# ログ確認
docker logs minio
```

### パフォーマンス最適化

**ZFS設定**:
```bash
# レコードサイズ最適化
zfs set recordsize=1M pool/minio

# 圧縮有効化
zfs set compression=lz4 pool/minio
```

**MinIO設定**:
```yaml
# メモリ最適化
MINIO_API_REQUESTS_MAX: "1000"
MINIO_API_REQUESTS_DEADLINE: "10s"
```

## 🔄 Ansible Roles連携

これらのプレイブックは以下のロールを使用します（roles 中心の構造に統一済み）：

- `roles/core`: TrueNAS基盤設定
- `roles/apps`: MinIOアプリケーション展開
- `roles/migrate-minio`: MinIOデータ移行（Phase A / Cutover / Full）

詳細な設定は各ロールの README.md を参照してください。

## 📈 パフォーマンス指標

- **setup.yml**: 5-15分（初回設定）
- **deploy-and-migrate.yml**: 30分-数時間（データサイズ依存）
- **phase-a.yml**: 10-30分
- **cutover.yml**: 5-15分

## 🤝 貢献

TrueNAS環境特有の改善提案やMinIO移行の最適化案は歓迎します：

1. TrueNAS APIの新機能活用
2. ZFS最適化の改善
3. 移行手順の効率化
4. エラーハンドリングの強化

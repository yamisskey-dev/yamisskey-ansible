# Yamisskey Provision - 運用Runbooks

本ディレクトリには、Yamisskey本番環境の緊急時対応および日常運用のためのRunbookを格納しています。

## 📋 Runbook一覧

### 緊急対応（Emergency Response）
- [`emergency-10min-recovery.md`](emergency-10min-recovery.md) - 🚨 **最小10分復旧チェックリスト**
- [`service-isolation.md`](service-isolation.md) - サービス分離・縮退運転手順
- [`network-failover.md`](network-failover.md) - ネットワーク障害時の迂回手順

### 日常運用（Daily Operations）
- [`health-monitoring.md`](health-monitoring.md) - ヘルスチェック・監視確認手順
- [`backup-verification.md`](backup-verification.md) - バックアップ検証・復旧テスト
- [`maintenance-procedures.md`](maintenance-procedures.md) - 定期メンテナンス手順

### トラブルシューティング（Troubleshooting）
- [`common-issues.md`](common-issues.md) - よくある問題と対処法
- [`performance-tuning.md`](performance-tuning.md) - パフォーマンス問題の調査・対処
- [`federation-issues.md`](federation-issues.md) - 連合関連問題の対処

## 🎯 使用方法

1. **緊急時**: [`emergency-10min-recovery.md`](emergency-10min-recovery.md)から開始
2. **計画メンテナンス**: [`maintenance-procedures.md`](maintenance-procedures.md)を参照
3. **日常監視**: [`health-monitoring.md`](health-monitoring.md)で定期チェック

## ⚠️ 重要事項

- すべてのRunbookは実際の障害事例・リハーサル結果に基づいて作成
- 手順実行前に必ずバックアップの存在確認を実施
- 不明な点があれば独断で進めず、チーム内で相談してから実行

## 📱 緊急連絡先

- DevOpsチーム: `#yamisskey-ops`
- システム管理者: `@yamisskey-admin`
- 外部サポート: 各サービスのサポート窓口（docs/CONTACTS.md参照）

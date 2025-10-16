# 🚨 緊急時最小10分復旧チェックリスト

**目的**: サービス停止から10分以内でYamisskeyの暫定復旧を実現する

## ⏰ Phase 1: 即座確認（0-2分）

### 1.1 サービス状態確認
```bash
# すべてのサービス状態をチェック
yamisskey-provision status
curl -s https://yami.ski/api/meta | jq -r '.version // "ERROR"'
```

**判定基準**:
- ✅ 200応答 → Phase 3へスキップ
- ❌ 50x応答 → Phase 2へ進行
- ❌ 無応答 → Phase 2へ進行

### 1.2 インフラ基盤確認
```bash
# 基本ネットワーク確認
ping -c 1 yami.ski
ping -c 1 8.8.8.8

# DNS確認
nslookup yami.ski
```

## 🔧 Phase 2: 緊急復旧（2-8分）

### 2.1 Misskey暫定復帰オプション

#### Option A: 通常再起動
```bash
cd /home/taka/.ghq/github.com/yamisskey-dev/yamisskey-provision
yamisskey-provision run site TARGET=servers LIMIT=balthasar
```

#### Option B: MinIO遅延時のローカル一時運用
```bash
# MinIOが応答しない場合の緊急措置
ssh balthasar
cd /opt/misskey
docker compose down
# .envでローカルストレージ設定に一時変更
sed -i 's/MINIO_ENDPOINT=.*/MINIO_ENDPOINT=local/' .env
docker compose up -d
```

#### Option C: 読み取り専用モード
```bash
# DB書き込み停止、読み取り専用で暫定運用
ssh balthasar
cd /opt/misskey
# 投稿機能無効化、タイムライン表示のみ
docker compose exec web node built/disable-posting.js
```

### 2.2 Cloudflaredトンネル迂回

#### トンネル死亡時の緊急切り替え
```bash
# Linodeプロキシ経由への一時切り替え
yamisskey-provision run deploy-proxy-services TARGET=servers LIMIT=linode_prox

# DNS切り替え（Cloudflare管理画面）
# A yami.ski -> Linode IP に変更
# CNAME削除、A レコードに切り替え
```

### 2.3 データベース緊急復旧
```bash
# PostgreSQL応答確認
ssh balthasar
docker compose exec db pg_isready

# 復旧が必要な場合
cd /opt/yamisskey-backup
python restore.py --emergency --restore-point latest
```

## 🔍 Phase 3: 状態検証（8-10分）

### 3.1 基本機能テスト
```bash
# API応答確認
curl -s https://yami.ski/api/meta | jq -r '.name'

# タイムライン取得テスト
curl -s -X POST https://yami.ski/api/notes/local-timeline \
  -H "Content-Type: application/json" \
  -d '{"limit": 1}' | jq -r 'length'

# WebSocket接続テスト
wscat -c wss://yami.ski/streaming
```

### 3.2 重要メトリクス確認
```bash
# Prometheus監視確認
curl -s http://caspar:9090/api/v1/query?query=up | jq -r '.data.result[].value[1]'

# ディスク容量確認
ssh balthasar "df -h | grep -E '(root|opt)'"
```

## ⚡ Phase 4: 連合制御（状況次第）

### 4.1 過負荷時の連合停止
```bash
ssh balthasar
cd /opt/misskey

# 連合配信を一時停止（受信は継続）
docker compose exec web node built/scripts/stop-federation.js

# 完全連合停止（緊急時のみ）
docker compose exec web node built/scripts/isolate-instance.js
```

### 4.2 連合再開
```bash
# 段階的連合再開
docker compose exec web node built/scripts/resume-federation.js --gradual

# 完全連合再開
docker compose exec web node built/scripts/resume-federation.js --full
```

## 📊 復旧完了チェックリスト

- [ ] メインページ（yami.ski）が正常表示
- [ ] API (`/api/meta`) が200応答
- [ ] ローカルタイムライン取得可能
- [ ] WebSocket接続可能
- [ ] MinIO（drive.yami.ski）アクセス可能
- [ ] 監視システム（Prometheus）正常
- [ ] ディスク容量十分（80%未満）

## 🚨 エスカレーション条件

以下の場合は10分復旧を断念し、完全復旧手順へ移行：

- [ ] データベース物理破損検出
- [ ] ストレージ完全障害（バックアップからの復元必要）
- [ ] ネットワーク基盤障害（ISP・データセンター側）
- [ ] 複数サーバー同時障害

→ [`../SECURITY.md`](../SECURITY.md) の完全災害復旧手順を実行

## 📝 事後対応

復旧完了後、必ず以下を実行：

1. **障害レポート作成**: [`incident-template.md`](incident-template.md) を使用
2. **ログ収集**:
   ```bash
   yamisskey-provision run collect-logs TARGET=all
   ```
3. **バックアップ検証**: 次回障害に備えた検証実施
4. **監視アラート確認**: 見逃したアラートがないかチェック

## 🔗 関連Runbook

- [サービス分離・縮退運転手順](service-isolation.md)
- [ネットワーク障害時の迂回手順](network-failover.md)
- [完全災害復旧手順](../SECURITY.md#disaster-recovery)

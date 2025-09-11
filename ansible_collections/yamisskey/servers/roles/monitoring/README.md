# yamisskey.servers role: monitoring

包括的なシステム監視とアラート機能を提供するAnsibleロールです。Prometheus、Grafana、各種Exporterによる監視基盤を構築します。

## 📋 概要

このロールは以下の監視スタックを展開します：

- **Prometheus**: メトリクス収集・保存・アラート
- **Grafana**: 可視化・ダッシュボード・通知
- **Node Exporter**: システムメトリクス収集
- **cAdvisor**: Dockerコンテナメトリクス
- **Blackbox Exporter**: エンドポイント死活監視
- **Cloudflared メトリクス**: Cloudflareトンネル監視

## 🏗️ 監視アーキテクチャ

```
                    ┌─────────────────────┐
                    │     Grafana         │
                    │   (Visualization)   │
                    └─────────┬───────────┘
                              │
                    ┌─────────▼───────────┐
                    │    Prometheus       │
                    │  (Metrics Storage)  │
                    └─────────┬───────────┘
                              │
                ┌─────────────┼─────────────┐
                │             │             │
        ┌───────▼──┐  ┌──────▼──┐  ┌──────▼──────┐
        │   Node   │  │cAdvisor │  │   Blackbox  │
        │ Exporter │  │(Docker) │  │  Exporter   │
        └──────────┘  └─────────┘  └─────────────┘
```

## 📁 ロール構造

```
monitoring/
├── tasks/
│   └── main.yml                    # メイン展開タスク
├── handlers/
│   └── main.yml                    # サービス再起動ハンドラー
├── templates/
│   ├── prometheus.yml.j2           # Prometheus設定
│   └── blackbox.yml.j2             # Blackbox Exporter設定
├── vars/
│   └── main.yml                    # ロール変数
└── README.md                       # このドキュメント
```

## ⚙️ 設定変数

### Grafana設定
```yaml
# Grafana サーバー設定
grafana_server_name: grafana.{{ domain }}
```

### 監視対象設定
```yaml
# ドメイン設定（group_vars/all.yml）
domain: 'yami.ski'

# 監視ポート設定
monitoring_ports:
  prometheus: 9090
  grafana: 3001
  node_exporter: 9100
  cadvisor: 8085
  blackbox: 9115
  alertmanager: 9093
```

## 📊 監視対象

### システムメトリクス
- **CPU使用率**: プロセス・アイドル・システム時間
- **メモリ使用量**: 使用量・キャッシュ・バッファ・スワップ
- **ディスク使用量**: マウントポイント別使用率・I/O統計
- **ネットワーク**: インターフェース別トラフィック・エラー率

### Dockerコンテナメトリクス
- **リソース使用量**: CPU・メモリ・ネットワーク・ディスクI/O
- **コンテナ状態**: 起動・停止・再起動回数
- **イメージ情報**: イメージサイズ・バージョン

### サービス死活監視
Blackbox Exporterによる HTTP エンドポイント監視：

#### ローカルサービス
- Grafana (localhost:3000)
- Prometheus (localhost:9090) 
- Node Exporter (localhost:9100)

#### Cloudflareトンネル経由サービス
- **yami.ski** (localhost:8080) - Misskey本体
- **search.yami.ski** (localhost:8082) - SearXNG検索
- **matrix.yami.ski** (localhost:8008) - Matrix/Synapse
- **chat.yami.ski** (localhost:8081) - Element チャット
- **ctf.yami.ski** (localhost:8000) - CTFd
- **drive.yami.ski** (localhost:9000) - MinIO
- **minio.yami.ski** (localhost:9001) - MinIO管理UI
- **grafana.yami.ski** (localhost:3000) - Grafana
- **task.yami.ski** (localhost:3456) - Vikunja
- **pad.yami.ski** (localhost:3333) - CryptPad
- **wiki.yami.ski** (localhost:3004) - Outline
- **uptime.yami.ski** (localhost:3009) - Uptime Kuma
- **auth.yami.ski** (localhost:8993) - Zitadel
- **captcha.yami.ski** (localhost:7493) - mCaptcha
- **neo-quesdon.yami.ski** (localhost:3025) - neo-quesdon

#### Cloudflaredメトリクス
- Cloudflaredトンネル統計 (localhost:49312)

## 🚀 使用方法

### 基本実行
```bash
# 監視システム全体展開
make run PLAYBOOK=monitoring

# ドライラン（設定確認）
make check PLAYBOOK=monitoring

# 特定コンポーネントのみ
make run PLAYBOOK=monitoring TAGS=prometheus
make run PLAYBOOK=monitoring TAGS=grafana
```

### セットアップフロー
```bash
# 1. 基盤環境準備
make run PLAYBOOK=common

# 2. 監視システム展開
make run PLAYBOOK=monitoring

# 3. Web UI アクセス確認
# Grafana: http://localhost:3001 (外部: https://grafana.yami.ski)
# Prometheus: http://localhost:9090

# 4. ダッシュボード設定
# Grafanaでデータソース設定 (Prometheus: http://localhost:9090)
```

## 📈 主要メトリクス

### システムパフォーマンス
```promql
# CPU使用率
100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# メモリ使用率
(node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100

# ディスク使用率
(node_filesystem_size_bytes - node_filesystem_avail_bytes) / node_filesystem_size_bytes * 100
```

### サービス可用性
```promql
# HTTP エンドポイント可用性
probe_success{job="blackbox"}

# レスポンス時間
probe_duration_seconds{job="blackbox"}

# HTTPステータスコード
probe_http_status_code{job="blackbox"}
```

### Dockerコンテナ
```promql
# コンテナCPU使用率
rate(container_cpu_usage_seconds_total[5m]) * 100

# コンテナメモリ使用量
container_memory_usage_bytes / container_spec_memory_limit_bytes * 100
```

## 🔧 設定詳細

### Prometheus設定 (`prometheus.yml.j2`)
```yaml
# スクレイプ間隔
global:
  scrape_interval: 15s
  evaluation_interval: 15s

# 監視ジョブ定義
scrape_configs:
  - job_name: 'prometheus'     # Prometheus自体
  - job_name: 'node'           # システムメトリクス
  - job_name: 'cadvisor'       # Dockerメトリクス
  - job_name: 'blackbox'       # エンドポイント監視
  - job_name: 'cloudflared'    # Cloudflareトンネル
```

### Blackbox Exporter設定 (`blackbox.yml.j2`)
```yaml
modules:
  http_2xx:
    prober: http
    http:
      valid_http_versions: ["HTTP/1.1", "HTTP/2.0"]
      valid_status_codes: [200]
      method: GET
```

## 🎯 アラート設定

### 推奨アラートルール
```yaml
# システムリソース
- alert: HighCPUUsage
  expr: 100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
  for: 5m

- alert: HighMemoryUsage  
  expr: (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100 > 90
  for: 5m

# サービス死活
- alert: ServiceDown
  expr: probe_success{job="blackbox"} == 0
  for: 2m

- alert: HighResponseTime
  expr: probe_duration_seconds{job="blackbox"} > 5
  for: 5m
```

## 🔗 Web UI アクセス

### Grafana
- **ローカル**: http://localhost:3001
- **外部**: https://grafana.yami.ski
- **デフォルト認証**: admin/admin (初回ログイン後変更)

### Prometheus
- **ローカル**: http://localhost:9090
- **機能**: メトリクス検索、ターゲット状態確認、アラート確認

## 📊 推奨ダッシュボード

### システム監視ダッシュボード
1. **Node Exporter Full** (ID: 1860)
2. **Docker Container & Host Metrics** (ID: 179)
3. **Blackbox Exporter** (ID: 7587)

### アプリケーション監視
1. **Misskey メトリクス**: カスタムダッシュボード
2. **MinIO ダッシュボード** (ID: 13502)
3. **Nginx メトリクス** (ID: 12559)

## 🐛 トラブルシューティング

### よくある問題

#### Prometheus 接続エラー
```bash
# Prometheus状態確認
curl http://localhost:9090/-/healthy

# 設定ファイル検証
promtool check config /etc/prometheus/prometheus.yml

# サービス状態確認
sudo systemctl status prometheus
```

#### Grafana 設定問題
```bash
# Grafana ログ確認
sudo journalctl -u grafana-server -f

# データソース接続テスト
curl -H "Content-Type: application/json" \
  http://localhost:3001/api/datasources/proxy/1/api/v1/query?query=up
```

#### メトリクス収集エラー
```bash
# Node Exporter 確認
curl http://localhost:9100/metrics | head -10

# cAdvisor 確認  
curl http://localhost:8085/metrics | head -10

# Blackbox プローブテスト
curl "http://localhost:9115/probe?target=http://localhost:3000&module=http_2xx"
```

## 🔧 カスタマイズ

### 監視対象追加
```yaml
# prometheus.yml.j2 に追加
- job_name: 'custom_service'
  static_configs:
    - targets: ['localhost:8080']
```

### アラート追加
```yaml
# アラートルールファイル作成
groups:
  - name: custom.rules
    rules:
      - alert: CustomServiceDown
        expr: up{job="custom_service"} == 0
        for: 1m
```

## 📈 パフォーマンス最適化

### Prometheus 最適化
- **保存期間**: デフォルト15日、調整可能
- **メモリ使用量**: 監視対象数に応じた調整
- **ストレージ**: SSD推奨、圧縮有効化

### 監視頻度調整
```yaml
# 高頻度監視（重要サービス）
scrape_interval: 5s

# 低頻度監視（一般メトリクス）  
scrape_interval: 30s
```

## 🔗 関連ドキュメント

- [**Prometheus公式**](https://prometheus.io/docs/) - Prometheus設定・運用
- [**Grafana公式**](https://grafana.com/docs/) - ダッシュボード・可視化
- [**サーバーロール一覧**](../README.md) - 他のロール詳細
- [**プロジェクト全体**](../../../../README.md) - 全体構成・使用方法

## 🔄 バックアップ・移行

### 設定バックアップ
```bash
# Grafana ダッシュボード エクスポート
curl -H "Authorization: Bearer $API_KEY" \
  http://localhost:3001/api/dashboards/db/dashboard-slug

# Prometheus 設定バックアップ
cp /etc/prometheus/prometheus.yml prometheus_backup_$(date +%Y%m%d).yml
```

### データ移行
```bash
# Prometheus データディレクトリ
/var/lib/prometheus/

# Grafana データディレクトリ  
/var/lib/grafana/
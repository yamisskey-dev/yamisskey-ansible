# yamisskey.servers role: monitoring - tasks

`monitoring` ロールのタスク定義を格納します。Prometheus/Grafana と各種 Exporter を導入し、ヘルスチェックまで行います。

主な処理:
- 事前準備: APT 前提パッケージ導入、`monitoring` Docker ネットワーク作成
- Node Exporter 稼働確認、Prometheus 常駐化
- cAdvisor コンテナのデプロイ
- Blackbox Exporter 設定生成（`blackbox.yml.j2`）とコンテナ起動
- Grafana リポジトリ登録・インストール・常駐化
- Prometheus 設定配備（`prometheus.yml.j2`）と `promtool` で検証、必要なら再起動
- 最終ヘルスチェック（各エンドポイントへの HTTP 確認）

実行例:
- 確認: `make check PLAYBOOK=monitoring`
- 実行: `make run PLAYBOOK=monitoring`

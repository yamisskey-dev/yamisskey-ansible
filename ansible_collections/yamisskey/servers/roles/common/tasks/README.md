# yamisskey.servers role: common - tasks

`common` ロールのタスク定義を格納します。基本セットアップ（パッケージ導入、無人アップデート）を行います。

主な処理:
- APT 更新・ディストリビューションアップグレード（タグ: `update`）
- 基本パッケージ導入（タグ: `packages`、内容は `vars/main.yml` の`packages`）
- unattended-upgrades の設定ファイル配備（`files/20auto-upgrades`）とサービス有効化

実行例:
- 確認: `make check PLAYBOOK=common`
- 実行: `make run PLAYBOOK=common`

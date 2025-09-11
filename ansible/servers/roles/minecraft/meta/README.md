# ansible/servers/roles/minecraft/meta

`minecraft` ロールのメタ情報（依存ロールや Galaxy 情報）を格納します。

- `meta/main.yml` の内容（要点）:
  - `galaxy_info`: 対応 OS（Ubuntu/Debian/RaspberryPiOS）やタグ、作者情報
  - `collections`: `community.docker` を使用
  - `dependencies`: なし

# Molecule テスト環境設定

このディレクトリには、yamisskey Ansibleプロジェクトの全ロールにMoleculeテスト環境を追加するためのテンプレートとスクリプトが含まれています。

## 📋 含まれるファイル

- `molecule.yml.template` - 標準のMolecule設定テンプレート
- `converge.yml.template` - テスト実行プレイブックテンプレート  
- `verify.yml.template` - 基本検証ルールテンプレート
- `setup_molecule.sh` - 全ロールへの自動セットアップスクリプト

## 🚀 インストールとセットアップ

### 1. Moleculeのインストール

```bash
# Nix環境ですべて自動インストール（direnvを推奨）
direnv allow
```

Molecule テストは既定で `nixos/nix:2.21.5` イメージを使用します。`prepare.yml` では
RAW モジュールで `nix --extra-experimental-features 'nix-command flakes' build` を実行し、
`nixpkgs#python312` を `/tmp/nix-python` にビルドしてから `/tmp/nix-python/bin/python3`
を Ansible のインタープリタとして利用します。プロファイルを汚さずに毎回クリーンな
Python 実行環境を確保する構成です。

### 2. Moleculeテスト設定の追加

```bash
# 全ロールにMolecule設定を追加（既に実行済み）
./molecule-templates/setup_molecule.sh
```

## 🧪 テストの実行

### 単一ロールのテスト

```bash
# 基本的なテスト実行
yamisskey-provision test common

# 構文チェックのみ
yamisskey-provision test common syntax

# コンバージテストのみ
yamisskey-provision test minio converge

# クリーンアップ
yamisskey-provision test system-init cleanup
```

### 全ロールのテスト

```bash
# 全ロール（servers）の基本テスト
yamisskey-provision test "" "" servers

# 全ロール（appliances）の構文チェック
yamisskey-provision test "" syntax appliances
```

## 📁 作成される構造

各ロールに以下の構造が追加されます：

```
role_name/
└── molecule/
    └── default/
        ├── molecule.yml    # Docker基盤のMolecule設定
        ├── converge.yml    # ロールを適用するプレイブック
        └── verify.yml      # 基本的な検証ルール
```

## ✨ カスタマイズ

### ロール固有の設定

各ロールの要件に応じて以下をカスタマイズできます：

1. **converge.yml** - ロール固有のテスト設定を追加
2. **verify.yml** - より具体的な検証ルールを追加
3. **molecule.yml** - プラットフォームや依存関係の調整

### 例：MinIOロールのカスタマイズ

```yaml
# converge.yml内でMinIO固有の設定
- name: Apply minio role
  include_role:
    name: yamisskey.servers.minio
  vars:
    minio_secrets_file: "/tmp/test-secrets.yml"
    minio_bucket_name_for_misskey: "test-misskey-files"
```

## 🔧 トラブルシューティング

### Dockerの設定

MoleculeはデフォルトでDockerを使用します。以下を確認してください：

```bash
# Dockerが実行中であることを確認
sudo systemctl status docker

# Dockerグループに追加（必要に応じて）
sudo usermod -aG docker $USER
```

### 権限の問題

```bash
# セットアップスクリプトに実行権限を付与
chmod +x molecule-templates/setup_molecule.sh
```

## 📖 参考リンク

- [Molecule Documentation](https://molecule.readthedocs.io/)
- [Ansible Testing](https://docs.ansible.com/ansible/latest/dev_guide/testing.html)
- [Docker Driver](https://molecule.readthedocs.io/en/latest/configuration.html#docker)

## 🎯 次のステップ

1. 各ロールでテストが正常に動作することを確認
2. CI/CDパイプラインにMoleculeテストを統合
3. ロール固有のテストシナリオを追加
4. テスト駆動開発（TDD）プロセスの導入

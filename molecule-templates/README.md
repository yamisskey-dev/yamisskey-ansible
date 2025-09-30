# Molecule テスト環境設定

このディレクトリには、yamisskey Ansibleプロジェクトの全ロールにMoleculeテスト環境を追加するためのテンプレートとスクリプトが含まれています。

## 📋 含まれるファイル

- `molecule.yml.template` - 標準のMolecule設定テンプレート
- `converge.yml.template` - テスト実行プレイブックテンプレート
- `verify.yml.template` - 基本検証ルールテンプレート
- `setup_molecule.sh` - 全ロールへの自動セットアップスクリプト

## 🚀 インストールとセットアップ

### 1. Moleculeのインストール

### 2. Moleculeテスト設定の追加

```bash
# 全ロールにMolecule設定を追加（既に実行済み）
./molecule-templates/setup_molecule.sh
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
    minio_bucket_name_for_misskey: "test-misskey-files"
```

## 🔧 トラブルシューティング

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

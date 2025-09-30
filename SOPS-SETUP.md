# SOPS暗号化セットアップガイド

このプロジェクトでは、secrets情報の漏洩を防ぐためにSOPS（Secrets OPerationS）を使用してsecrets.ymlファイルを暗号化しています。

## セットアップ

### 1. 必要なツールのインストール

#### macOS
```bash
brew install sops age
```

#### Ubuntu/Debian
```bash
apt-get install sops age
```

#### その他のOS
- [SOPS](https://github.com/mozilla/sops/releases) からダウンロード
- [Age](https://github.com/FiloSottile/age/releases) からダウンロード

### 2. SOPS設定の初期化

```bash
./scripts/setup-sops.sh
```

このスクリプトは以下を実行します：
- Age keyの生成（`~/.config/sops/age/keys.txt`）
- `.sops.yaml`の更新
- セキュリティ設定の確認

### 3. pre-commitフックの設定

pre-commitフックが自動的に以下を実行します：

1. **コミット前**: secrets.ymlファイルを復号化してlintingを実行
2. **コミット後**: secrets.ymlファイルを再暗号化

## 使用方法

### ファイルの暗号化

```bash
# 手動で暗号化
sops --encrypt --in-place --age "age1..." path/to/secrets.yml

# または、pre-commitフックが自動実行
git add path/to/secrets.yml
git commit -m "Update secrets"
```

### ファイルの復号化

```bash
# 手動で復号化
sops --decrypt --in-place --age "age1..." path/to/secrets.yml

# または、編集用に一時的に復号化
sops path/to/secrets.yml
```

### 新しいsecretsファイルの追加

1. ファイルを作成（例：`new-secrets.yml`）
2. 内容を記述
3. コミット時に自動的に暗号化されます

## セキュリティ注意事項

⚠️ **重要**: 以下のファイルは絶対にGitにコミットしないでください：

- `~/.config/sops/age/keys.txt` (秘密鍵)
- `age-key.txt`
- `*.decrypted`
- `*.backup`

## トラブルシューティング

### SOPSが見つからない場合
```bash
# パスを確認
which sops
which age

# インストール確認
sops --version
age --version
```

### Age keyが見つからない場合
```bash
# キーファイルの場所を確認
ls -la ~/.config/sops/age/keys.txt

# キーを再生成
./scripts/setup-sops.sh
```

### 暗号化に失敗する場合
```bash
# 公開鍵を確認
grep -o 'age1[^"]*' ~/.config/sops/age/keys.txt

# .sops.yamlの設定を確認
cat .sops.yaml
```

## チームでの使用

1. **初回セットアップ**: 各メンバーが `./scripts/setup-sops.sh` を実行
2. **公開鍵の共有**: チームメンバー間で公開鍵を安全に共有
3. **.sops.yamlの更新**: 新しいメンバーの公開鍵を追加

## ファイル構造

```
yamisskey-provision/
├── .sops.yaml                    # SOPS設定ファイル
├── .gitignore                    # Git除外設定（age key等）
├── .pre-commit-config.yaml       # pre-commit設定
├── scripts/
│   ├── setup-sops.sh            # セットアップスクリプト
│   ├── pre-commit-sops-decrypt.sh  # 復号化フック
│   └── pre-commit-sops-reencrypt.sh # 再暗号化フック
└── deploy/servers/group_vars/all/
    └── secrets.yml              # 暗号化されたsecretsファイル
```

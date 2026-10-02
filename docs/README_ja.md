# dotenv module for V

[English](../README.md)
/ Japanese

.env ファイルから環境変数を読み込みます。
https://github.com/joho/godotenv に触発されて作りました。


[module document.](docs/vdotenv.md)


## Usage

アプリケーションの設定をプロジェクトのルートにある.envファイルに追加します。
```
S3_BUCKET=YOURS3BUCKET
DYNAMODB_TABLE=YOURDYNAMODBTABLE
```

その後、Vのアプリで次のようなことができます。
```v
import os

import zztkm.vdotenv

fn main() {
    // loads env vars from a .env file.
    vdotenv.load()

    s3_bucket := os.getenv('S3_BUCKET')
    dynamodb_table := os.getenv('DYNAMODB_TABLE')

    // ...
}
```

デフォルトでは、loadは現在の作業ディレクトリにある.envというファイルを探しますが、以下のようにファイルを指定することもできます。
```v
vdotenv.load(".env.develop") // load `.env.development`
vdotenv.load(".env", ".env.develop") // load `.env` and `.env.develop`
```

envファイルにコメントを書くことができます。
```
# This is comment
FOO=BAR
API_URL=YOUR_API_URL # This is inline comment
```

## シリアライズ形式と互換性

`marshal()`、`write()`、`print_file()`、`print_terminal()` は `KEY="VALUE"` 形式で出力します。
キーは `[A-Za-z_][A-Za-z0-9_]*` に制限し、不正なキーがあればエラーを返します。
値のバックスラッシュ、二重引用符、LF、CR、タブは、それぞれ `\\`、`\"`、`\n`、`\r`、`\t` にエスケープします。
引用符内の空白、`#`、`=`、単一引用符は保持します。

```v
env_map := { 'USER_INPUT': 'hello\nADMIN=enabled' }
encoded := vdotenv.marshal(env_map) or { panic(err) }
assert vdotenv.unmarshal(encoded) == env_map
vdotenv.write(env_map, 'config.env') or { panic(err) }
```

`marshal()` の戻り値は `string` から `!string` に、`print_terminal()` は戻り値なしから `!` に変更しています。
呼び出し元では `!` でエラーを伝播するか、`or { ... }` で処理してください。
`write()` と `print_file()` の Result 型は変更せず、キーの検証エラーも返すようにしています。
検証エラーが発生した場合、出力ファイルの作成や上書きは行いません。

読み込みでは、引用符なしの値とインラインコメントを引き続き利用できます。
二重引用符内では上記のエスケープを復元し、未知のエスケープはバックスラッシュごと保持します。
単一引用符内は文字列をそのまま扱うため、従来と異なり `\n` も展開しません。
最初の `=` だけをキーと値の区切りとし、引用符の外にある `#` だけをコメントの開始とみなします。
物理的に複数行にまたがる引用値と変数展開には対応しないため、複数行の値には `\n` や `\r` を使用してください。
出力は dotenv の読み込み用であり、シェルスクリプトとして実行するための形式ではありません。

## Installation and Import

### Using vpm:

Install/Update:
```
v install zztkm.vdotenv
```

Import:
```v
import zztkm.vdotenv
```

### Using github (least recommended):

Install (from your project folder):
```
git clone https://github.com/zztkm/vdotenv.git
```

Update (from your project folder):
```
cd vdotenv
git pull
```

Import:
```
import vdotenv
```

## Contributing

[Contributing Guide for this repository.](docs/CONTRIBUTING.md)

## License

[MIT License](LICENSE.txt)

## 謝辞

- [ivixvi](https://github.com/ivixvi)
- [ksk001100](https://github.com/ksk001100)
- [nyx-litenite](https://github.com/nyx-litenite)

## 開発者

- [zztkm](https://github.com/zztkm/vdotenv)
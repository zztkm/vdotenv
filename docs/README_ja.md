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
    vdotenv.load() or { panic(err) }

    s3_bucket := os.getenv('S3_BUCKET')
    dynamodb_table := os.getenv('DYNAMODB_TABLE')

    // ...
}
```

デフォルトでは、loadは現在の作業ディレクトリにある.envというファイルを探しますが、以下のようにファイルを指定することもできます。
```v
vdotenv.load(".env.develop") or { panic(err) } // load `.env.develop`
vdotenv.load(".env", ".env.develop") or { panic(err) } // load both files
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
assert vdotenv.unmarshal(encoded) or { panic(err) } == env_map
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

## 解析エラーと API 互換性

空白だけの行と、先頭に空白のあるコメント行は無視します。
`=` のない行、空のキー、閉じていない引用値、閉じ引用符の後にコメント以外の文字がある値は `vdotenv.ParseError` を返します。
`line` フィールドは入力文字列またはファイル内の物理行番号（1 始まり）で、`reason` はエラーの理由です。
エラーメッセージには入力行、キー、値を含めません。

`unmarshal()` は `!map[string]string`、`parse()` は `!string`、`load()` と `over_load()` は `!` を返すように変更しています。
従来は通常の値（または戻り値なし）を返し、不正な行を読み飛ばしていました。
`print_file()` と `print_terminal()` の Result 型は変更せず、解析エラーも伝播させます。
呼び出し元では `or { ... }` で処理するか、`!` で伝播してください。

```v
env_map := vdotenv.unmarshal('INVALID_LINE') or {
    if err is vdotenv.ParseError {
        eprintln('Invalid dotenv input on line ${err.line}')
    }
    return
}
```

最初の不正な行で解析を停止し、途中までのマップや出力は返しません。
`load()` と `over_load()` は、ファイル全体の解析に成功してから環境変数を設定します。
複数ファイルを指定した場合、先に読み込みに成功したファイルの設定は保持しますが、不正なファイルと後続のファイルは適用しません。
解析エラー時に `print_file()` は出力ファイルを作成せず、`print_terminal()` は環境変数の値を出力しません。
存在しないファイルや読み込めないファイルは、従来どおり診断を表示して空の入力として扱います。

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
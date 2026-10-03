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

`marshal()` と `print_terminal()` は `KEY="VALUE"` 形式で出力します。
キーは `[A-Za-z_][A-Za-z0-9_]*` に制限し、不正なキーがあればエラーを返します。
値のバックスラッシュ、二重引用符、LF、CR、タブは、それぞれ `\\`、`\"`、`\n`、`\r`、`\t` にエスケープします。
引用符内の空白、`#`、`=`、単一引用符は保持します。

```v
env_map := { 'USER_INPUT': 'hello\nADMIN=enabled' }
encoded := vdotenv.marshal(env_map) or { panic(err) }
assert vdotenv.unmarshal(encoded) or { panic(err) } == env_map
```

`marshal()` の戻り値は `string` から `!string` に、`print_terminal()` は戻り値なしから `!` に変更しています。
呼び出し元では `!` でエラーを伝播するか、`or { ... }` で処理してください。
`print_terminal()` はキーの検証エラーも返し、エラー時には環境変数の値を出力しません。

読み込みでは、引用符なしの値とインラインコメントを引き続き利用できます。
二重引用符内では上記のエスケープを復元し、未知のエスケープはバックスラッシュごと保持します。
単一引用符内は文字列をそのまま扱うため、従来と異なり `\n` も展開しません。
最初の `=` だけをキーと値の区切りとし、引用符の外にある `#` だけをコメントの開始とみなします。
物理的に複数行にまたがる引用値と変数展開には対応しないため、複数行の値には `\n` や `\r` を使用してください。
出力は dotenv の読み込み用であり、シェルスクリプトとして実行するための形式ではありません。

## 入力パスと UTF-8 BOM と NUL

ファイルパスは指定どおりに使用し、先頭や末尾の空白を除去しません。
既定の読み込み先は、引き続き現在の作業ディレクトリの `.env` です。

すべての読み込み API は、入力文字列または各ファイルの先頭にある UTF-8 BOM（`EF BB BF`）を 1 個だけ無視します。
先頭が代入行、コメント、空行の場合と、BOM だけの入力を、BOM なしの入力と同じように解析します。
値や途中のキーに現れる同じ文字は保持し、解析エラーの物理行番号も変えません。

`load()`、`over_load()`、`parse()` は、解析したキーや値に NUL（`0x00`）があれば `ParseError` を返します。
OS と JSON エンコーダーによる名前や値の切り詰めを防ぐための制限です。
重複キーの先行行や、`load()` が既存値を保持する変数も検証します。
検証エラーがあれば、そのファイルの環境変数は一切適用しません。
`unmarshal()` はメモリ内の処理用に NUL を保持し、`marshal()` も値の NUL を保持しますが、その文字列を OS の設定関数へ直接渡さないでください。
環境変数への適用や JSON 出力に使う設定からは NUL を除去してください。

`load()` は空の値も含め、既存の環境変数を保持します。
OS の設定失敗はキーや値を含まないエラーとして返すため、`!` で伝播するか `or { ... }` で処理してください。
OS の失敗では後続の設定を停止しますが、すでに設定した変数は元に戻しません。
適用前に行う入力検証とは異なるため、設定失敗時にファイル全体の適用が取り消されることを前提にしないでください。

## 端末への表示

`print_terminal()` は `.env` のキーから現在のプロセス環境の値を取得して表示します。
`KEY="VALUE"` 形式と、バックスラッシュ、引用符、LF、CR、タブのエスケープは維持します。
残りの C0 制御文字（`U+0000` から `U+001F`）と DEL（`U+007F`）は `\xNN` で表示し、ESC は `\x1b` と表示します。
Unicode の C1 制御文字（`U+0080` から `U+009F`）は `\u00NN` と表示し、不正な UTF-8 は置換文字に変換します。
通常の Unicode の文字列は保持します。
解析やキー検証のエラー時には、環境変数の値を出力しません。

この表示形式は、元の値を復元するための dotenv の保存形式ではありません。
端末出力を保存したりデコードしたりする処理は、値のマップを `marshal()` でシリアライズする方法に変更してください。
`marshal()` と `unmarshal()` による制御文字の往復変換は維持します。

## JSON 出力とファイル名のコメント

`parse(false, filenames...)` は、プロセスの環境変数を変更せず、キーと値をフラットな JSON オブジェクトとして返します。
ファイル名を省略すると `.env` を読み込みます。
キーと値には V の標準 JSON エンコーダーを使用し、引用符、バックスラッシュ、制御文字をエスケープします。

```v
import json

output := vdotenv.parse(false, '.env') or { panic(err) }
env_map := json.decode(map[string]string, output) or { panic(err) }
```

`parse()` による NUL の拒否を除き、入力キーの受理範囲は維持します。
最初の `=` より前の文字列から前後の空白を除去し、非空ならキーとして受理します。
キー内の引用符、バックスラッシュ、タブ、記号、日本語は文字列として扱い、JSON の構文にはしません。
空行とコメント行は無視し、物理的な CR と LF は行の区切りなのでキー内には記載できません。
`marshal()` のキー制限より広い範囲を受理するため、dotenv として再出力する場合は `[A-Za-z_][A-Za-z0-9_]*` に合うキーを使用してください。

`parse(true, filenames...)` は同じフラットなオブジェクトに、各ファイルの項目の前へ `/* file: NAME */` 形式のブロックコメントを追加します。
空ファイルにもコメントを付けます。
これはコメント付き JSON であり、厳密な JSON ではありません。
標準 JSON デコーダーで読む場合は `false` を指定してください。
`NAME` は JSON 文字列のエスケープ済み内容から外側の引用符を除いたもので、すべての `/` をさらに `\u002f` に置換します。
ファイル名にコメントの開始や終端が含まれていても、コメントの構文として解釈されません。
改行とタブもエスケープします。
たとえば `config/.env` のラベルは `config\u002f.env` になります。

非空ファイルの単純な ASCII キー、値、ファイル名の配置は維持しますが、特殊なキー、値、ファイル名のラベルには JSON のエスケープを使用します。
出力テキストを元の値と直接比較せず、キーと値は JSON デコードして取得してください。
ファイル名のラベルを取得する処理は、ラベルを二重引用符で囲み、JSON 文字列としてデコードする方法に変更してください。

空ファイルによってカンマは追加しません。
従来どおり、同じファイル名の指定は 1 回だけ処理し、異なるファイル間の重複キーはファイル順に出力します。
重複キーの解釈は JSON デコーダーに依存するため、移植可能な結果が必要な場合はファイル間でもキーを一意にしてください。

## ファイル出力 API の廃止

破壊的変更として、`write()` と `print_file()` を削除しました。
vdotenv は出力ファイルの作成や上書きを行いません。
`marshal()` は残し、保存先、権限や ACL、上書き方法、書き込みエラーの処理は呼び出し元に任せます。
`print_terminal()` は引き続き利用できます。

`write(env_map, filename)` の代わりに、シリアライズした文字列をアプリケーション側で保存してください。

```v
contents := vdotenv.marshal(env_map) or { panic(err) }
// Apply your application's file permission/ACL policy before writing contents.
```

`print_file()` の代わりに、`.env` のキーから現在のプロセス環境の値を取得してシリアライズしてください。

```v
file_contents := os.read_file('.env') or { panic(err) }
file_env_map := vdotenv.unmarshal(file_contents) or { panic(err) }
mut current_env := map[string]string{}
for key in file_env_map.keys() {
    current_env[key] = os.getenv(key)
}
contents := vdotenv.marshal(current_env) or { panic(err) }
// Choose an output filename and write contents using your application's policy.
```

秘密情報を保存する POSIX の書き込み処理では、新規ファイルを `0600` などの制限された権限で作成してください。
既存ファイルは、切り詰めや書き込みの前に権限を制限するか、書き込みを拒否してください。
Windows では適切な ACL を設定してください。
一般的なファイル書き込み関数だけで、秘密情報の保護が保証されるとは限りません。

## 解析エラーと API 互換性

空白だけの行と、先頭に空白のあるコメント行は無視します。
`=` のない行、空のキー、閉じていない引用値、閉じ引用符の後にコメント以外の文字がある値は `vdotenv.ParseError` を返します。
`line` フィールドは入力文字列またはファイル内の物理行番号（1 始まり）で、`reason` はエラーの理由です。
エラーメッセージには入力行、キー、値を含めません。

`unmarshal()` は `!map[string]string`、`parse()` は `!string`、`load()` と `over_load()` は `!` を返すように変更しています。
従来は通常の値（または戻り値なし）を返し、不正な行を読み飛ばしていました。
`print_terminal()` も解析エラーを伝播させます。
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
解析エラー時に `print_terminal()` は環境変数の値を出力しません。
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

公式リリースの V と Python 3 を使用し、`make test test-integration`、`v fmt -verify .`、`v vet -W .` を実行してください。
V のテストは専用の一時ディレクトリを使用し、アサーションの成功時も失敗時も後始末します。
テストと `make clean` は、作業ディレクトリの `.env` と `.env.parse` を上書きも削除もしません。

## License

[MIT License](LICENSE.txt)

## 謝辞

- [ivixvi](https://github.com/ivixvi)
- [ksk001100](https://github.com/ksk001100)
- [nyx-litenite](https://github.com/nyx-litenite)

## 開発者

- [zztkm](https://github.com/zztkm/vdotenv)
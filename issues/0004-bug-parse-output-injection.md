# parse の出力にエスケープされていないキーを注入できる

- Created: 2026-10-03
- Completed: {YYYY-MM-DD}
- Branch: feature/fix-parse-output-injection
- Polished: {YYYY-MM-DD}

## 目的

dotenv 入力のキーが `parse()` の出力構造として解釈され、意図しない項目が追加されることを防ぐ。

## 現状

対象は `vdotenv.v` の `parse()`。
入力キーの検証については `parse_lines()` も関連する。

`parse()` は JSON 風の文字列を手作業で組み立てる。
キーはエスケープせずに埋め込み、値は二重引用符だけを置換する。
そのため、キーに JSON の構文を含めると、別の項目を出力に追加できる。
値のバックスラッシュや制御文字についても、JSON 文字列に必要なエスケープが不足している。

macOS、V 0.5.2 c0e8c7b、コミット `70988e0` の一時コピーでキー注入を再現した。
生成した文字列を Python の `json.load()` で読み込み、`A` と `ROLE` の 2 項目になることも確認した。

## 再現手順

リポジトリの一時コピーに次のテストを追加し、`v test parse_probe_test.v` を実行する。

```v
module vdotenv

import os

fn test_parse_output_injection() {
    os.write_file('json-injection.env', 'A" : "safe", "ROLE=admin\n')!
    result := parse(false, 'json-injection.env')
    assert result == '{ "A" : "safe", "ROLE" : "admin" }'
    os.write_file('json-injection.json', result)!
}
```

入力は 1 行で、キーは `A" : "safe", "ROLE`、値は `admin`。

```dotenv
A" : "safe", "ROLE=admin
```

しかし、出力を JSON として解釈すると 2 項目になる。

```json
{ "A" : "safe", "ROLE" : "admin" }
```

## 影響と成立条件

攻撃者が dotenv ファイルの内容を操作でき、下流のアプリが `parse(false, ...)` の出力を JSON などの構造化データとして使用する場合、意図しない設定項目を渡せる。
下流での利用方法によっては設定改ざんにつながる。

不正な環境変数名を入力段階で拒否できれば、この再現例は成立しない。
ただし、値のエスケープ不足はキーの検証だけでは解消しない。

`include_names=true` の既存出力にはコメントが含まれ、厳密な JSON ではない。
修正ではこの形式と互換性を区別して扱う必要がある。

## 設計方針

- JSON 部分は標準の JSON エンコーダーで生成し、キーと値の両方を安全にエスケープする。
- 入力キーの許容形式を定義する。
- `include_names=true` の出力形式を明確にし、ファイル名をコメントに埋め込む処理も構文を壊さないようにする。
- 出力形式や API を変更する場合は互換性への影響を記載する。
- キーだけの検証や二重引用符だけの置換を、完全なエスケープの代替として採用しない。

## 完了条件

- [ ] 再現例を拒否するか、1 つのキーとして安全に出力し、JSON の解析結果に別の `ROLE` 項目が追加されない。
- [ ] `include_names=false` の出力を標準の JSON デコーダーで解析できる。
- [ ] 引用符、バックスラッシュ、タブ、改行を含むキーまたは値について、拒否または正確な復元を確認する回帰テストがある。
- [ ] `include_names=true` の形式が定義され、コメント終端などを含むファイル名で構文を壊せないことをテストで確認できる。
- [ ] 既存テストが通るか、出力形式の変更に合わせて期待値が更新され、互換性の変更がドキュメントに反映されている。

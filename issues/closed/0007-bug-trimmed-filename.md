# ファイル名の空白を除去して別の設定ファイルを読み込む

- Created: 2026-10-03
- Completed: 2026-10-03
- Branch: feature/fix-trimmed-filename
- Polished: {YYYY-MM-DD}

## 目的

呼び出し元が指定したファイルをそのまま読み込み、別の設定ファイルを適用しない。

## 現状

対象は `vdotenv.v` の `read_file()` と、これを使用する `load()`、`over_load()`、`parse()`。

`read_file()` は `os.read_file(filename.trim_space())` を呼び出す。
指定されたパスの先頭・末尾に空白があると、別のパスに変更される。
`parse(true, ...)` のファイル名コメントには元の指定が使われるため、表示された名前と実際に読んだパスも一致しない。

macOS、公式 V 0.5.2（7647ce1）、コミット `a01d748` の一時コピーで、末尾に空白を持つファイルではなく、空白を除去した名前のファイルを読み込むことを確認した。

## 再現手順

リポジトリの一時コピーに次のテストを追加し、`v test filename_probe_test.v` を実行する。
以下のアサーションは、修正前の誤った読み込みを確認するためのもの。

```v
module vdotenv

import json
import os

fn test_trailing_space_filename() {
    requested := 'filename-probe.env '
    other := 'filename-probe.env'
    defer {
        os.rm(requested) or {}
        os.rm(other) or {}
    }
    os.write_file(requested, 'VALUE=requested\n')!
    os.write_file(other, 'VALUE=other\n')!
    output := parse(false, requested)!
    assert json.decode(map[string]string, output)!['VALUE'] == 'other'
}
```

本来の結果は `requested`。
空白を除去した名前のファイルが存在しない場合は、指定したファイルが存在していても読み込みに失敗する。

## 影響と成立条件

優先度は中。
有効なファイル名に先頭・末尾の空白を含める場合、設定を読み込めないか、別ファイルの設定を適用する。
その別ファイルを第三者が操作できる場合は、意図しない設定を読み込む可能性がある。

OS ごとのファイル名の制約は別途確認が必要。
再現したのは macOS の末尾空白付きファイル名である。

## 設計方針

- `read_file()` ではファイル名をトリミングせず、指定されたパスをそのまま使用する。
- 不正なパスを拒否する必要がある場合も、黙って別のパスへ置換しない。
- ファイル名コメントには、実際に読み込んだ指定を反映する。
- ファイル内容中のキー・値に対する空白の処理とは区別する。

## 完了条件

- [x] 対応 OS で先頭・末尾に空白を含むファイル名を指定した場合、そのファイルを読み込む。
- [x] 空白を除去した名前の別ファイルが存在していても、その内容を読み込まない。
- [x] `load()`、`over_load()`、`parse()` の回帰テストがある。
- [x] `parse(true, ...)` のコメントに記載したファイル名と読み込み対象が一致する。
- [x] 通常の相対パス・絶対パスおよび既定の `.env` の読み込みを維持する。

## 解決方法

- `read_file()` の `trim_space()` を削除し、指定されたパスをそのまま `os.read_file()` に渡すようにした。
  README と API ドキュメントにもパスの空白を保持する仕様を記載した。
- `load()`、`over_load()`、`parse()` で先頭と末尾に空白を持つ相対パスと絶対パスを検証した。
  空白を除去した別ファイルの存在時と不在時に指定ファイルを読み、`parse(true, ...)` のファイル名コメントも指定と一致することを確認した。
- 公式 V 0.5.2（7647ce1）の macOS と Ubuntu 24.04（arm64）で `make test test-integration`、整形、lint が成功した。
  通常のパスと既定の `.env` を使う既存テストも成功した。

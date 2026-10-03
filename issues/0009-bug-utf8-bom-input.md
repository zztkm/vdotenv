# UTF-8 BOM 付き入力を通常の dotenv として読み込めない

- Created: 2026-10-03
- Completed: {YYYY-MM-DD}
- Branch: feature/fix-utf8-bom-input
- Polished: {YYYY-MM-DD}

## 目的

UTF-8 BOM 付きファイルの扱いを定義し、利用者が通常のキーで設定を取得できると誤認しないようにする。

## 現状

対象は `vdotenv.v` の `parse_contents()`、`parse_lines()` と、それらを使用する `unmarshal()`、`parse()`、`load()`、`over_load()`、`print_terminal()`。
対応形式の説明は `README.md`、`docs/README_ja.md`、`docs/vdotenv.md` にある。

解析前に入力先頭の UTF-8 BOM（`EF BB BF`）を除去していない。
BOM 付きの `TOKEN=value` は、BOM を含む別名のキーとして受理される。
先頭がコメントの場合は `#` で始まる行と認識されず、区切り文字がないため解析エラーになる。

macOS、公式 V 0.5.2（7647ce1）、コミット `a01d748` の一時コピーで、解析後のキーのバイト列が `efbbbf544f4b454e` となることを確認した。

BOM 対応は現行ドキュメントで約束されていない。
この issue は既存の明示的な仕様違反ではなく、互換性上の穴と対応方針の未定義を扱う。

## 再現手順

リポジトリの一時コピーに次のテストを追加し、`v test bom_probe_test.v` を実行する。
以下のアサーションは、修正前の挙動を確認するためのもの。

```v
module vdotenv

fn test_bom_becomes_part_of_key() {
    env_map := unmarshal('\xef\xbb\xbfTOKEN=value\n')!
    assert env_map.keys()[0].bytes().hex() == 'efbbbf544f4b454e'
    assert 'TOKEN' !in env_map
}

fn test_bom_prefixed_comment_is_rejected() {
    mut rejected := false
    unmarshal('\xef\xbb\xbf# comment\nTOKEN=value\n') or {
        rejected = true
        assert err is ParseError
    }
    assert rejected
}
```

ファイルに同じバイト列を書いた場合も、共通の解析処理を通る。
BOM を無視して読み込む方針なら、本来は通常の `TOKEN` を取得でき、先頭のコメントも無視できる必要がある。

## 影響と成立条件

優先度は中の互換性課題。
エディターなどが UTF-8 BOM を付けた設定ファイルで、最初のキーを通常の名前で取得できないか、先頭のコメントによって読み込みが失敗する。

既存の仕様では非空のキーを広く受理するため、BOM の除去を入力全体へ無条件に適用すると、値や途中のキーに含まれる同じ文字まで変更するおそれがある。

## 設計方針

- UTF-8 BOM を対応対象にするか、非対応として明記するかを決める。
- 対応する場合は入力の先頭にある BOM だけを取り除き、その後に通常の解析を行う。
- 値や入力途中に現れる同じ文字を一括置換で除去する方式は採用しない。
- BOM は物理行ではないため、除去しても解析エラーの行番号を変えない。
- 非対応を選ぶ場合は、その制約と BOM なしで保存する方法を説明する。明示的に拒否するかも決める。

## 完了条件

- [ ] BOM の対応方針が README と API ドキュメントに明記されている。
- [ ] 対応する場合、先頭の通常行・コメント・空行および BOM だけの入力を扱う回帰テストがある。
- [ ] 対応する場合、文字列入力とファイル入力で通常のキーを取得でき、BOM なしの入力と同じ解析結果になる。
- [ ] 対応する場合、入力途中や値に含まれる同じ文字を保持し、解析エラーの物理行番号を維持する。
- [ ] 非対応を選ぶ場合、BOM なしで保存する手順と現行または変更後の挙動が説明され、その挙動をテストで確認できる。
- [ ] 対応範囲や入力仕様を変更する場合は CHANGELOG に反映し、既存テストが通る。

BOM 非対応を明記する方針では、通常のキーとして読み込めるように直した扱いにはしない。
その場合は互換性上の制約を明文化した対応として閉じる。

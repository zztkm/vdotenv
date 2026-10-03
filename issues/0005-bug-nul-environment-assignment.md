# NUL 文字を含む入力で別名の環境変数を設定し、値を切り詰める

- Created: 2026-10-03
- Completed: {YYYY-MM-DD}
- Branch: feature/fix-nul-environment-assignment
- Polished: {YYYY-MM-DD}

## 目的

dotenv のキーと値を、解析結果とは異なる名前や内容でプロセス環境に適用しない。
設定に失敗した場合は、呼び出し元が失敗を判別できるようにする。

## 現状

対象は `vdotenv.v` の `parse_lines()`、`load_env()`、`load_env_map()` と、公開 API の `load()`、`over_load()`。
`parse_value()` も NUL 文字を値として保持する。

解析処理はキーと値に含まれる NUL 文字を拒否しない。
`load_env_map()` はその文字列を `os.setenv()` に渡し、戻り値を無視する。
macOS の C API では NUL が文字列の終端になるため、解析時と設定時で名前や値が異なる。

macOS、公式 V 0.5.2（7647ce1）、コミット `a01d748` の一時コピーで次を確認した。

- キー `VDOTENV_PROBE_ALIAS<NUL>IGNORED` は、実際には `VDOTENV_PROBE_ALIAS` を設定する。
- 値 `before<NUL>after` は `before` に切り詰められる。
- NUL から始まるキーでは `os.setenv()` が `-1` を返すが、`over_load()` は成功扱いになる。

`<NUL>` は説明用の表記で、実際の入力は `0x00` バイト。
既存のキー検証はシリアライズ用であり、ファイルの読み込みには適用されない。
JSON 出力の構文や、改行による変数の追加とは別の問題である。

## 再現手順

リポジトリの一時コピーに次のテストを追加し、公式 V 0.5.2 で `v test nul_probe_test.v` を実行する。
以下のアサーションは、修正前の挙動を確認するためのもの。

```v
module vdotenv

import os

fn test_nul_environment_assignment() {
    filename := 'nul-probe.env'
    alias := 'VDOTENV_PROBE_ALIAS'
    value_key := 'VDOTENV_PROBE_NUL_VALUE'
    defer {
        os.rm(filename) or {}
        os.unsetenv(alias)
        os.unsetenv(value_key)
    }
    os.unsetenv(alias)
    os.unsetenv(value_key)
    os.write_file(filename, '${alias}\x00IGNORED=changed\n${value_key}="before\x00after"\n')!
    over_load(filename)!
    assert os.getenv(alias) == 'changed'
    assert os.getenv(value_key) == 'before'

    os.write_file(filename, '\x00INVALID=value\n')!
    assert os.setenv('\x00INVALID', 'value', true) == -1
    over_load(filename)!
}
```

## 影響と成立条件

優先度は高。
入力を操作できる場合、解析時のキーと異なる環境変数を設定できる。
`over_load()` では既存値も上書きされる。
`load()` は既存値を保持するが、未設定の変数には同じ問題がある。

値の切り詰めや設定失敗を検知できないため、正常に設定できたと判断してアプリが動作する可能性がある。
本件だけでリモートからのコード実行が成立することは確認していない。

## 設計方針

- 環境変数への適用前に、ファイル内の全キーと全値について NUL 文字を検証する。
- 不正な入力は適用前に拒否し、同じファイルの先行する正常な変数も設定しない。
- `os.setenv()` の失敗を無視せず、呼び出し元に伝播する。既存値を保持する正常な処理と OS の失敗を区別する。
- `unmarshal()` と `parse()` にも NUL の拒否を適用するかは、既存の入力仕様との整合性を確認して決める。
- エラーにはキー、値、入力行の実値を含めない。

## 完了条件

- [ ] キーの先頭・途中・末尾に NUL がある入力を、別名の環境変数を設定せず拒否できる。
- [ ] NUL を含む値を黙って切り詰めず、呼び出し元がエラーを判別できる。
- [ ] 同じファイルに正常な行と NUL を含む行が混在しても、検証エラー時に環境変数を部分適用しない。
- [ ] OS の設定失敗を通知し、既存値を保持する `load()` の正常動作は維持する。
- [ ] `load()` と `over_load()` の回帰テストがあり、エラーに入力の実値が含まれない。
- [ ] 入力仕様を変更する場合、README、API ドキュメント、CHANGELOG に反映する。

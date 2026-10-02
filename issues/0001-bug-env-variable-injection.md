# 改行を含む値のシリアライズで環境変数を追加できる

- Created: 2026-10-03
- Completed: {YYYY-MM-DD}
- Branch: feature/fix-env-variable-injection
- Polished: {YYYY-MM-DD}

## 目的

外部入力を dotenv 形式に保存した際に、値の改行が別の環境変数の定義として解釈されることを防ぐ。

## 現状

対象は `vdotenv.v` の `format_env_map()`、`marshal()`、`write()`。
`print_file()` も同じフォーマッターを使用する。

`format_env_map()` はキーと値を検証せず、引用もエスケープもせずに `KEY=VALUE\n` として連結する。
値に改行と別の変数定義を含めると、保存後の `load()` でその変数も設定される。

macOS、V 0.5.2 c0e8c7b、コミット `70988e0` の一時コピーで再現した。

## 再現手順

リポジトリの一時コピーに次のテストを追加し、`v test injection_probe_test.v` を実行する。
ファイル名と環境変数は検証用のものを使用する。

```v
module vdotenv

import os

fn test_env_variable_injection() {
    env_map := {
        'USER_INPUT': 'hello\nVDOTENV_PROBE_ADMIN=enabled'
    }
    encoded := marshal(env_map)
    assert unmarshal(encoded)['VDOTENV_PROBE_ADMIN'] == 'enabled'

    write(env_map, 'injection.env')!
    os.unsetenv('VDOTENV_PROBE_ADMIN')
    load('injection.env')
    assert os.getenv('VDOTENV_PROBE_ADMIN') == 'enabled'
}
```

保存される内容は次のとおり。

```dotenv
USER_INPUT=hello
VDOTENV_PROBE_ADMIN=enabled
```

## 影響と成立条件

攻撃者がマップの値を操作でき、アプリが `marshal()` または `write()` の出力を後から環境変数として読み込む場合に、意図しない設定を追加できる。
設定の用途によっては認証や動作モードに影響する。

`load()` は既存の環境変数を上書きしないため、既存値の改ざんには `over_load()` などの上書きを行う読み込みが必要。
本件だけでリモートからのコード実行が成立することは確認していない。

## 設計方針

- キーの許容形式を定義し、改行や区切り文字を含む不正なキーを拒否する。
- 値を引用し、改行、引用符、バックスラッシュをエスケープする。
- シリアライズと読み込みの規則を揃え、値を別の変数として解釈させない。
- キーの検証エラーを呼び出し元へ伝える方法を決め、公開 API の互換性への影響を記載する。

## 完了条件

- [ ] 再現例の値を保存して読み込んでも `VDOTENV_PROBE_ADMIN` が追加されず、`USER_INPUT` の元の値を復元できる。
- [ ] 改行や `=` を含む不正なキーを、定義した規則に従って拒否できる。
- [ ] 改行、引用符、バックスラッシュ、`#` を含む値について往復変換の回帰テストがある。
- [ ] `marshal()`、`write()` と同じフォーマッターを使う経路に修正が適用され、既存テストが通る。
- [ ] 公開 API や対応形式を変更した場合、ドキュメントに反映されている。

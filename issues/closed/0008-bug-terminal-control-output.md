# print_terminal が端末制御文字をそのまま出力する

- Created: 2026-10-03
- Completed: 2026-10-03
- Branch: feature/fix-terminal-control-output
- Polished: {YYYY-MM-DD}

## 目的

環境変数の値を確認する際に、値に含まれる制御文字で端末表示が操作されることを防ぐ。

## 現状

対象は `vdotenv.v` の `print_terminal()` と、同関数が使用する `format_env_map()`。

`print_terminal()` は `.env` からキーを取得し、そのキーに対応する現在のプロセス環境の値を表示する。
表示には保存用のフォーマッターを使用する。
フォーマッターは LF、CR、タブなどをエスケープするが、ESC やその他の制御文字はそのまま出力する。

macOS、公式 V 0.5.2（7647ce1）、コミット `a01d748` の一時コピーで、画面消去とカーソル移動の制御列が標準出力へ出ることを確認した。
端末で実際に制御列を実行する必要はなく、出力をファイルに捕捉して確認した。

## 再現手順

リポジトリの一時コピーに次のテストを追加する。
`.env` は専用ディレクトリ内に作成する。

```v
module vdotenv

import os

fn test_terminal_control_output() {
    key := 'VDOTENV_PROBE_TERMINAL'
    directory := 'terminal-probe'
    previous_directory := os.getwd()
    os.mkdir(directory)!
    defer {
        os.chdir(previous_directory) or {}
        os.rmdir_all(directory) or {}
        os.unsetenv(key)
    }
    os.chdir(directory)!
    os.write_file('.env', '${key}=placeholder\n')!
    os.setenv(key, '\x1b[2J\x1b[Hspoofed', true)
    print_terminal()!
    // 意図的に失敗させ、テストランナーに標準出力を表示させる。
    assert false, 'Capture stdout to inspect control bytes'
}
```

端末へ直接出力せず、次のコマンドで捕捉する。

```sh
v test terminal_probe_test.v > terminal-output.log 2>&1
python3 - <<'PY'
from pathlib import Path
data = Path('terminal-output.log').read_bytes()
assert b'\x1b[2J\x1b[Hspoofed' in data
print('Raw terminal control bytes were emitted')
PY
```

`v test` の失敗は出力を捕捉するための意図的なもので、上記は回帰テストの期待値ではない。

## 影響と成立条件

優先度は中。ただし、信頼できない値を端末へ表示する場合に限る。
値を操作できる場合、画面消去、カーソル移動などによって表示を偽装できる。
利用する端末によっては、別の端末制御機能も解釈される可能性がある。

確認したのは制御列の未加工の出力であり、任意のシェルコマンドの実行は確認していない。
`print_terminal()` が環境変数の値を表示すること自体や、保存用の `marshal()` が値を保持することとは区別する。

## 設計方針

- 端末表示用の処理を保存用のシリアライズから分離する。
- 値に含まれる ESC などの制御文字は、可視の表記へ変換して表示する。
- 保存用の `marshal()` の往復変換を壊す対処は採用しない。
- 表示形式の変更と互換性への影響をドキュメントに記載する。

## 完了条件

- [x] ESC を含む値を表示しても、値由来の ESC バイトを標準出力へ出さない。
- [x] その他の端末制御文字についても扱いを定義し、表示を操作できないことを出力バイトで検証する。
- [x] 通常の値を表示でき、既存の解析エラー・キー検証エラー時に値を出力しない動作を維持する。
- [x] `marshal()` と `unmarshal()` の往復変換は維持する。
- [x] 標準出力を捕捉する回帰テストと、表示形式のドキュメントがある。

## 解決方法

- 保存用の `format_env_map()` を変更せず、表示専用の `format_terminal_env_map()` を追加した。
  従来の dotenv エスケープに加え、C0 と DEL を `\xNN`、Unicode の C1 を `\u00NN` に変換し、不正な UTF-8 は置換文字に変換する。
- subprocess の標準出力をバイト列として捕捉し、値に由来する ESC、C0、DEL、C1 の未加工出力がないこと、通常の Unicode 表示、解析やキー検証のエラー時の無出力を検証した。
  保存用の制御文字の往復変換も確認した。
- 表示専用形式と保存時の移行方法を README、API ドキュメント、CHANGELOG に記載した。
  公式 V 0.5.2（7647ce1）の macOS と Ubuntu 24.04（arm64）で全テスト、整形、lint が成功した。

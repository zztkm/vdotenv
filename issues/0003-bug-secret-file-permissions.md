# 秘密情報の保存ファイルが他ユーザーにも読める権限で作成される

- Created: 2026-10-03
- Completed: {YYYY-MM-DD}
- Branch: feature/fix-secret-file-permissions
- Polished: {YYYY-MM-DD}

## 目的

環境変数の値を保存するファイルを、所有者以外が読めない権限で作成する。

## 現状

対象は `vdotenv.v` の `write()`、`write_file()`、`print_file()`。

`write()` と `write_file()` は `os.write_file()` を使用し、秘密情報を保存するための権限を指定していない。
`print_file()` は実際のプロセス環境から取得した値を `write_file()` で保存する。

macOS、V 0.5.2 c0e8c7b、コミット `70988e0` の一時コピーで、`umask 022` のときに両方の出力が `0644` になることを確認した。

## 再現手順

リポジトリの一時コピーに次のテストを追加する。
`print_file()` が参照する `.env` を上書きするため、実際の秘密情報がある作業ディレクトリでは実行しない。

```v
module vdotenv

import os

fn test_secret_file_permissions() {
    write({'SECRET': 'dummy-security-test'}, 'secret-output.env')!
    os.write_file('.env', 'SECRET=dummy-security-test\n')!
    os.setenv('SECRET', 'dummy-runtime-secret', true)
    print_file()!
}
```

一時コピー内で次を実行する。

```sh
umask 022
v test permissions_probe_test.v
ls -l secret-output.env .env\ *
```

`secret-output.env` とタイムスタンプ付きの `.env` の両方が `-rw-r--r--` で作成される。

## 影響と成立条件

保存先の親ディレクトリを通過できる別ユーザーがいる場合、ファイルに保存した API キーや認証情報を読める可能性がある。
親ディレクトリが `0700` などで保護されている場合、この権限設定だけで他ユーザーへの漏えいが成立するとは限らない。

`0644` での作成を再現したのは新規ファイル。
既存ファイルへの書き込み時に権限をどう扱うかは、修正時に別途確認する必要がある。

## 設計方針

- POSIX 環境では、新規ファイルを作成する時点で `0600` を指定する。
- 書き込み後の権限変更だけでは、変更までの間に読める時間が生じるため、その方式だけで対処しない。
- 広い権限を持つ既存ファイルは、秘密情報を書き込む前に権限を制限するか、書き込みを拒否する。
- 権限設定に失敗した場合はエラーを返す。
- 非 POSIX 環境での保護方法と制約を明記する。

## 完了条件

- [ ] macOS と Linux で `umask 022` および `umask 000` の場合にも、新規出力ファイルの権限が `0600` になる。
- [ ] `write()` と `print_file()` の両方で権限を検証する回帰テストがある。
- [ ] 既存の `0644` ファイルに対し、権限を制限してから書き込むか、安全に書き込みを拒否できる。
- [ ] 権限設定の失敗を呼び出し元が判別できる。
- [ ] 既存テストが通り、対応プラットフォームと権限の仕様がドキュメントに反映されている。

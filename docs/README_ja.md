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
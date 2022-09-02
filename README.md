# dotenv module for V
[![Latest version][version-badge]][version-url] [![CI](https://github.com/zztkm/vdotenv/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/zztkm/vdotenv/actions/workflows/ci.yml)

English
/ [Japanese](./docs/README_ja.md)

vdotenv is a module to read environment variables from `.env` files

- Which loads env vars from a .env file.
- Existing environment variables can be overridden in the program
- Inspired by https://github.com/joho/godotenv.


[module document.](docs/vdotenv.md)

## Usage

Add your application configuration to your `.env` file in the root of your project:
```
S3_BUCKET=YOURS3BUCKET
DYNAMODB_TABLE=YOURDYNAMODBTABLE
```

Then in your V app you can do something like

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
By default, load looks for a file called .env in your current working directory, but you can also specify the file as follows:
```v
vdotenv.load(".env.develop") // load `.env.development`
vdotenv.load(".env", ".env.develop") // load `.env` and `.env.develop`
```

You can write comments in the env file:
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

[docs]: https://github.com/zztkm/vdotenv
[version-badge]: https://img.shields.io/github/v/release/zztkm/vdotenv?logo=github&logoColor=white
[version-url]: https://github.com/zztkm/vdotenv/releases/latest
[workflow-badge]: https://img.shields.io/github/workflow/status/zztkm/vdotenv/CI?label=test&logo=github&logoColor=white
[workflow-url]: https://github.com/zztkm/vdotenv/actions?query=workflow%3ACI

## TDOO

- [ ] [cli app](https://github.com/zztkm/vdotenv/issues/13)
- [ ] README: add tutorial(for dotenv beginner)

## Acknowledgement

- [ivixvi](https://github.com/ivixvi)
- [ksk001100](https://github.com/ksk001100)
- [nyx-litenite](https://github.com/nyx-litenite)

## Author

- [zztkm](https://github.com/zztkm/vdotenv)

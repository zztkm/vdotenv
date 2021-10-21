# dotenv module for V

[![Latest version][version-badge]][version-url] [![Workflow status][workflow-badge]][workflow-url]

English
/ [Japanese](./docs/README_ja.md)

Which loads env vars from a .env file.
Inspired by https://github.com/joho/godotenv.


[module document.](docs/vdotenv.md)

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

## Usage

Add your application configuration to your .env file in the root of your project:
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

## Contributing

[Contributing Guide for this repository.](docs/CONTRIBUTING.md)

## License

[MIT License](LICENSE.txt)

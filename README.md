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
    vdotenv.load() or { panic(err) }

    s3_bucket := os.getenv('S3_BUCKET')
    dynamodb_table := os.getenv('DYNAMODB_TABLE')

    // ...
}
```
By default, load looks for a file called .env in your current working directory, but you can also specify the file as follows:
```v
vdotenv.load(".env.develop") or { panic(err) } // load `.env.develop`
vdotenv.load(".env", ".env.develop") or { panic(err) } // load both files
```

You can write comments in the env file:
```
# This is comment
FOO=BAR
API_URL=YOUR_API_URL # This is inline comment
```

## Serialization and compatibility

`marshal()`, `write()`, `print_file()` and `print_terminal()` emit `KEY="VALUE"` lines.
Keys must match `[A-Za-z_][A-Za-z0-9_]*`; invalid keys return an error rather than being written.
Values escape backslashes, double quotes, LF, CR and tabs as `\\`, `\"`, `\n`, `\r` and `\t`.
Spaces, `#`, `=` and single quotes are preserved inside the double-quoted value.

```v
env_map := { 'USER_INPUT': 'hello\nADMIN=enabled' }
encoded := vdotenv.marshal(env_map) or { panic(err) }
assert vdotenv.unmarshal(encoded) or { panic(err) } == env_map
vdotenv.write(env_map, 'config.env') or { panic(err) }
```

**API change:** `marshal()` now returns `!string` instead of `string`, and `print_terminal()` now returns `!` instead of returning no value.
Callers must propagate errors with `!` or handle them with `or { ... }`.
`write()` and `print_file()` retain their Result signatures and also propagate key validation errors.
Validation errors do not create or overwrite output files.

Reading still supports unquoted values and inline comments.
Double-quoted values decode the escapes above; unknown escapes retain their backslash.
Single-quoted values are literal, including backslashes (unlike the previous decoder, which also expanded `\n` in single quotes).
Only the first `=` separates a key from its value, and `#` starts a comment only outside a quoted value.
Physical multiline quoted values and variable interpolation are not supported; write multiline values using escaped `\n` or `\r`.
The output is intended for dotenv readers, not for execution as a shell script.

## Parse errors and API compatibility

Blank lines (including whitespace-only lines) and comments with leading whitespace are ignored.
A missing `=`, an empty key, an unclosed quoted value, or non-comment text after a closing quote returns `vdotenv.ParseError`.
Its `line` field is the 1-based physical line number within the input or file, and `reason` describes the error.
Error messages include neither the input line nor its key or value.

**API change:** `unmarshal()` now returns `!map[string]string`, `parse()` returns `!string`, and `load()` and `over_load()` return `!`.
These functions previously returned plain values (or no value) and silently skipped malformed lines.
`print_file()` and `print_terminal()` retain their Result signatures and now propagate parse errors too.
Handle errors with `or { ... }` or propagate them with `!`:

```v
env_map := vdotenv.unmarshal('INVALID_LINE') or {
    if err is vdotenv.ParseError {
        eprintln('Invalid dotenv input on line ${err.line}')
    }
    return
}
```

Parsing stops at the first malformed line and does not return a partial map or output.
`load()` and `over_load()` apply variables only after a whole file parses successfully.
When loading multiple files, earlier successful files remain applied; the malformed file and subsequent files are not applied.
`print_file()` creates no output file and `print_terminal()` prints no environment values on a parse error.
The existing missing/unreadable-file behavior is unchanged: a diagnostic is printed and that file is treated as empty.

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

```bash
v install --git https://github.com/zztkm/vdotenv
```

Import:
```v
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

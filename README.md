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

`marshal()` and `print_terminal()` emit `KEY="VALUE"` lines.
Keys must match `[A-Za-z_][A-Za-z0-9_]*`; invalid keys return an error rather than being written.
Values escape backslashes, double quotes, LF, CR and tabs as `\\`, `\"`, `\n`, `\r` and `\t`.
Spaces, `#`, `=` and single quotes are preserved inside the double-quoted value.

```v
env_map := { 'USER_INPUT': 'hello\nADMIN=enabled' }
encoded := vdotenv.marshal(env_map) or { panic(err) }
assert vdotenv.unmarshal(encoded) or { panic(err) } == env_map
```

**API change:** `marshal()` now returns `!string` instead of `string`, and `print_terminal()` now returns `!` instead of returning no value.
Callers must propagate errors with `!` or handle them with `or { ... }`.
`print_terminal()` propagates key validation errors without printing environment values.

Reading still supports unquoted values and inline comments.
Double-quoted values decode the escapes above; unknown escapes retain their backslash.
Single-quoted values are literal, including backslashes (unlike the previous decoder, which also expanded `\n` in single quotes).
Only the first `=` separates a key from its value, and `#` starts a comment only outside a quoted value.
Physical multiline quoted values and variable interpolation are not supported; write multiline values using escaped `\n` or `\r`.
The output is intended for dotenv readers, not for execution as a shell script.

## File output API removal

**Breaking change:** `write()` and `print_file()` have been removed.
vdotenv no longer creates or overwrites output files.
`marshal()` remains available; the caller chooses the destination, permissions or ACLs, overwrite behavior, and write-error handling.
`print_terminal()` remains available.

Replace `write(env_map, filename)` with serialization followed by your application's own writer:

```v
contents := vdotenv.marshal(env_map) or { panic(err) }
// Apply your application's file permission/ACL policy before writing contents.
```

To replace `print_file()`, read the keys from `.env`, retrieve their current process values, and serialize them:

```v
file_contents := os.read_file('.env') or { panic(err) }
file_env_map := vdotenv.unmarshal(file_contents) or { panic(err) }
mut current_env := map[string]string{}
for key in file_env_map.keys() {
    current_env[key] = os.getenv(key)
}
contents := vdotenv.marshal(current_env) or { panic(err) }
// Choose an output filename and write contents using your application's policy.
```

For secret files, a POSIX writer should create new files with restricted permissions (for example, `0600`) and restrict or reject existing files before truncating or writing them.
On Windows, use an appropriate ACL policy.
Do not assume that a generic file-writing function makes secrets private.

## Parse errors and API compatibility

Blank lines (including whitespace-only lines) and comments with leading whitespace are ignored.
A missing `=`, an empty key, an unclosed quoted value, or non-comment text after a closing quote returns `vdotenv.ParseError`.
Its `line` field is the 1-based physical line number within the input or file, and `reason` describes the error.
Error messages include neither the input line nor its key or value.

**API change:** `unmarshal()` now returns `!map[string]string`, `parse()` returns `!string`, and `load()` and `over_load()` return `!`.
These functions previously returned plain values (or no value) and silently skipped malformed lines.
`print_terminal()` also propagates parse errors.
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
`print_terminal()` prints no environment values on a parse error.
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

# module vdotenv


## Contents
- [load](#load)
- [marshal](#marshal)
- [over_load](#over_load)
- [parse](#parse)
- [print_terminal](#print_terminal)
- [unmarshal](#unmarshal)
- [ParseError](#ParseError)
  - [msg](#msg)
  - [code](#code)

## load
```v
fn load(filenames ...string) !
```

load create environment variables from the values in specified files; default to .env [note: Does not overwrite env variables that already exist.] Returns ParseError before setting any variables from a malformed file.

[[Return to contents]](#Contents)

## marshal
```v
fn marshal(env_map map[string]string) !string
```

marshal outputs the given environment as a dotenv-formatted environment file. Each line is in the format: KEY="VALUE", with escaped backslashes, double quotes, newlines, carriage returns and tabs. Keys must match [A-Za-z_][A-Za-z0-9_]*. Returns an error for invalid keys.

[[Return to contents]](#Contents)

## over_load
```v
fn over_load(filenames ...string) !
```

over_load create environment variables from specified files; default to .env [note: Overwrites env variables that already exist.] 環境変数を上書きする. Returns ParseError before setting any variables from a malformed file.

[[Return to contents]](#Contents)

## parse
```v
fn parse(include_names bool, filenames ...string) !string
```

parse writes contents of files into a format easily parsed by other systems without modifying environment Returns ParseError for malformed input instead of returning partial output.

[[Return to contents]](#Contents)

## print_terminal
```v
fn print_terminal() !
```

print_terminal prints the values set in .env file to the terminal .envファイルに記載されている環境変数に関して現在の設定状況をターミナルに表示する． Returns ParseError for malformed input, or an error if a key cannot be serialized. No environment values are printed on error.

[[Return to contents]](#Contents)

## unmarshal
```v
fn unmarshal(str string) !map[string]string
```

unmarshal reads an env file from a string, returning a map of keys and values. Double-quoted values decode \\, \", \n, \r and \t escapes; single-quoted values are literal. Hashes inside quotes and equals signs in values are preserved. Blank lines and indented comments are ignored. Malformed lines return ParseError.

[[Return to contents]](#Contents)

## ParseError
```v
struct ParseError {
pub:
	line   int
	reason string
}
```

ParseError identifies a malformed dotenv line without exposing its key or value. line is the 1-based physical line number within the input or file; reason is a safe description.

[[Return to contents]](#Contents)

## msg
```v
fn (err ParseError) msg() string
```

msg returns the line number and reason without exposing input keys or values.

[[Return to contents]](#Contents)

## code
```v
fn (err ParseError) code() int
```

code returns the default error code (0) required by IError.

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 3 Oct 2026 11:11:41

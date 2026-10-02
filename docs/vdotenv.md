# module vdotenv


## Contents
- [load](#load)
- [marshal](#marshal)
- [over_load](#over_load)
- [parse](#parse)
- [print_file](#print_file)
- [print_terminal](#print_terminal)
- [unmarshal](#unmarshal)
- [write](#write)

## load
```v
fn load(filenames ...string)
```

load create environment variables from the values in specified files; default to .env [note: Does not overwrite env variables that already exist.]

[[Return to contents]](#Contents)

## marshal
```v
fn marshal(env_map map[string]string) !string
```

marshal outputs the given environment as a dotenv-formatted environment file. Each line is in the format: KEY="VALUE", with escaped backslashes, double quotes, newlines, carriage returns and tabs. Keys must match [A-Za-z_][A-Za-z0-9_]*. Returns an error for invalid keys.

[[Return to contents]](#Contents)

## over_load
```v
fn over_load(filenames ...string)
```

over_load create environment variables from specified files; default to .env [note: Overwrites env variables that already exist.] 環境変数を上書きする.

[[Return to contents]](#Contents)

## parse
```v
fn parse(include_names bool, filenames ...string) string
```

parse writes contents of files into a format easily parsed by other systems without modifying environment

[[Return to contents]](#Contents)

## print_file
```v
fn print_file() !
```

print_file writes the values set in .env file to a file Returns an error if a key cannot be serialized, without creating an output file. .envファイルに記載されている環境変数に関して，現在の設定状況をファイルに書き出す．

[[Return to contents]](#Contents)

## print_terminal
```v
fn print_terminal() !
```

print_terminal prints the values set in .env file to the terminal .envファイルに記載されている環境変数に関して現在の設定状況をターミナルに表示する． Returns an error if a key cannot be serialized.

[[Return to contents]](#Contents)

## unmarshal
```v
fn unmarshal(str string) map[string]string
```

unmarshal reads an env file from a string, returning a map of keys and values. Double-quoted values decode \\, \", \n, \r and \t escapes; single-quoted values are literal. Hashes inside quotes and equals signs in values are preserved.

[[Return to contents]](#Contents)

## write
```v
fn write(env_map map[string]string, filename string) !
```

write serializes the given environment and writes it to a file. Invalid keys return an error without creating or overwriting the file.

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 3 Oct 2026 03:02:20

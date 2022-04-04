# module 

## Contents
- [load](#load)
- [over_load](#over_load)
- [parse](#parse)
- [print_file](#print_file)
- [print_terminal](#print_terminal)

## load
```v
fn load(filenames ...string)
```

load create environment variables from the values in specified files; default to .env [note: Does not overwrite env variables that already exist.]

[[Return to contents]](#Contents)

## over_load
```v
fn over_load(filenames ...string)
```

over_load create environment variables from specified files; default to .env
[note: Overwrites env variables that already exist.] 環境変数を上書きする.  

[[Return to contents]](#Contents)

## parse
```v
fn parse(include_names bool, filenames ...string) string
```

parse writes contents of files into a format easily parsed by other systems without modifying environment

[[Return to contents]](#Contents)

## print_file
```v
fn print_file()
```

print_file writes the values set in .env file to a file .envファイルに記載されている環境変数に関して，現在の設定状況をファイルに書き出す．

[[Return to contents]](#Contents)

## print_terminal
```v
fn print_terminal()
```

print_terminal prints the values set in .env file to the terminal .envファイルに記載されている環境変数に関して現在の設定状況をターミナルに表示する．

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 4 Apr 2022 11:59:37

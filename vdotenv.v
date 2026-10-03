module vdotenv

import json
import os
import strings

// ParseError identifies a malformed dotenv line without exposing its key or value.
// line is the 1-based physical line number within the input or file; reason is a safe description.
pub struct ParseError {
pub:
	line   int
	reason string
}

// msg returns the line number and reason without exposing input keys or values.
pub fn (err ParseError) msg() string {
	return 'dotenv parse error on line ${err.line}: ${err.reason}'
}

// code returns the default error code (0) required by IError.
pub fn (err ParseError) code() int {
	return 0
}

// load create environment variables from the values in specified files; default to .env
// [note: Does not overwrite env variables that already exist.]
// Paths are used verbatim; one initial UTF-8 BOM is ignored.
// Returns ParseError before setting any variables from a malformed file or NUL key/value.
// OS setter failures return a safe error; variables already set are not rolled back.
pub fn load(filenames ...string) ! {
	if filenames.len > 0 {
		for filename in filenames {
			load_env(filename, false)!
		}
	} else {
		load_env('.env', false)!
	}
}

// over_load create environment variables from specified files; default to .env
// [note: Overwrites env variables that already exist.] 環境変数を上書きする.
// Paths are used verbatim; one initial UTF-8 BOM is ignored.
// Returns ParseError before setting any variables from a malformed file or NUL key/value.
// OS setter failures return a safe error; variables already set are not rolled back.
pub fn over_load(filenames ...string) ! {
	if filenames.len > 0 {
		for filename in filenames {
			load_env(filename, true)!
		}
	} else {
		load_env('.env', true)!
	}
}

// marshal outputs the given environment as a dotenv-formatted environment file.
// Each line is in the format: KEY="VALUE", with escaped backslashes, double quotes,
// newlines, carriage returns and tabs. Keys must match [A-Za-z_][A-Za-z0-9_]*.
// Returns an error for invalid keys.
pub fn marshal(env_map map[string]string) !string {
	return format_env_map(env_map)
}

// unmarshal reads an env file from a string, returning a map of keys and values.
// Double-quoted values decode \\, \", \n, \r and \t escapes; single-quoted values are literal.
// Hashes inside quotes and equals signs in values are preserved.
// Keys are the nonempty, whitespace-trimmed text before the first =; punctuation is literal.
// Physical CR/LF delimit lines and cannot occur inside keys.
// One initial UTF-8 BOM, blank lines and indented comments are ignored.
// Malformed lines return ParseError. NUL is preserved for in-memory serialization;
// load, over_load and parse reject NUL keys/values before calling OS or JSON APIs.
pub fn unmarshal(str string) !map[string]string {
	return parse_contents(str)
}

// print_terminal prints the values set in .env file to the terminal
// .envファイルに記載されている環境変数に関して現在の設定状況をターミナルに表示する．
// Returns ParseError for malformed input, or an error if a key cannot be serialized.
// One initial UTF-8 BOM is ignored. No environment values are printed on error.
// In addition to dotenv escapes, C0 controls and DEL use visible \xNN notation,
// and Unicode C1 controls use \u00NN. Invalid UTF-8 becomes replacement characters.
// This is display-only text; use marshal for lossless serialization.
pub fn print_terminal() ! {
	filename := '.env'
	contents := read_file(filename)
	if contents == '' {
		return
	}
	file_env_map := parse_contents(contents)!
	os_env_map := read_env_var(file_env_map.keys())
	println(format_terminal_env_map(os_env_map)!)
}

// parse returns a flat object of JSON-encoded keys and values without modifying environment.
// With include_names=false the output is strict JSON. With include_names=true it is
// JSON with /* file: NAME */ comments; NAME is JSON string contents with / escaped as \u002f.
// Empty files add no commas. Duplicate keys across files remain in file order.
// Paths are used verbatim; one initial UTF-8 BOM is ignored in each file.
// Returns ParseError for malformed input or NUL keys/values, without partial output.
pub fn parse(include_names bool, filenames ...string) !string {
	files := parse_files(filenames)!
	mut output_builder := strings.new_builder(100)
	output_builder.write_string('{ ')
	mut has_entries := false
	for fname, variables in files {
		if has_entries && variables.len > 0 {
			output_builder.write_string(', ')
		} else if has_entries && include_names {
			output_builder.write_string(' ')
		}
		if include_names {
			encoded_name := json.encode(fname)
			label := encoded_name[1..encoded_name.len - 1].replace('/', '\\u002f')
			output_builder.write_string('/* file: ${label} */ ')
		}
		for i, key in variables.keys() {
			if i > 0 {
				output_builder.write_string(', ')
			}
			output_builder.write_string('${json.encode(key)} : ${json.encode(variables[key])}')
			has_entries = true
		}
	}
	output_builder.write_string(' }')
	return output_builder.str()
}

// load_env_map sets/overwrites enviroments variables with values from env_map
fn load_env_map(env_map map[string]string, over_load bool) ! {
	for key, value in env_map {
		if !over_load {
			if _ := os.getenv_opt(key) {
				continue
			}
		}
		if os.setenv(key, value, over_load) != 0 {
			return error('failed to set environment variable')
		}
	}
}

// read_file read file contents into a string fileを読み込む
fn read_file(filename string) string {
	contents := os.read_file(filename) or {
		println('Failed to open ${filename}')
		return ''
	}
	return contents
}

// read_env_var match the specified keys to their values and return the resulting map
// 引数で渡されたキーに紐づく環境変数を読み込み keys and values で返却する.
fn read_env_var(keys []string) map[string]string {
	mut env_map := map[string]string{}
	for key in keys {
		env_map[key] = os.getenv(key)
	}
	return env_map
}

// parse_files parse the contents of a variable number of files into map of environment variables by file
fn parse_files(filenames []string) !map[string]map[string]string {
	mut files := map[string]map[string]string{}
	if filenames.len > 0 {
		for filename in filenames {
			contents := read_file(filename)
			variables := parse_lines(dotenv_lines(contents), true)!
			files[filename] = variables.clone()
		}
	} else {
		contents := read_file('.env')
		variables := parse_lines(dotenv_lines(contents), true)!
		files['.env'] = variables.clone()
	}
	return files
}

// parse_contents parses the contents of a file's contents and returns a map of environment variable
// .envファイルから読み込んだcontentsをkeys and values で返却する．
fn parse_contents(contents string) !map[string]string {
	return parse_lines(dotenv_lines(contents), false)
}

// dotenv_lines removes only one BOM at the start, without changing physical line numbers.
fn dotenv_lines(contents string) []string {
	if contents.starts_with('\xef\xbb\xbf') {
		return contents[3..].split_into_lines()
	}
	return contents.split_into_lines()
}

// parse_lines return a map of environment variables by parsing the lines of a file
// env file から読み込んだ各行を keys and values で返却する.
fn parse_lines(lines []string, reject_nul bool) !map[string]string {
	mut env_map := map[string]string{}
	for index, raw_line in lines {
		line := raw_line.trim_space()
		if line == '' || line.starts_with('#') {
			continue
		}
		separator := line.index('=') or {
			return ParseError{
				line:   index + 1
				reason: 'missing = separator'
			}
		}
		key := line[..separator].trim_space()
		if key == '' {
			return ParseError{
				line:   index + 1
				reason: 'empty key'
			}
		}
		value := parse_value(line[separator + 1..]) or {
			return ParseError{
				line:   index + 1
				reason: 'invalid quoted value'
			}
		}
		if reject_nul && (key.contains('\x00') || value.contains('\x00')) {
			return ParseError{
				line:   index + 1
				reason: 'NUL in key or value'
			}
		}
		env_map[key] = value
	}
	return env_map
}

// parse_value decodes quoted values without treating escaped quotes or hashes as delimiters.
fn parse_value(raw_value string) ?string {
	value := raw_value.trim_space()
	if value == '' {
		return ''
	}
	quote := value[0]
	if quote != `"` && quote != `'` {
		return value.all_before('#').trim_space()
	}
	mut decoded := strings.new_builder(value.len)
	mut i := 1
	for i < value.len {
		ch := value[i]
		if ch == quote {
			trailing := value[i + 1..].trim_space()
			if trailing != '' && !trailing.starts_with('#') {
				return none
			}
			return decoded.str()
		}
		if quote == `"` && ch == `\\` && i + 1 < value.len {
			next := value[i + 1]
			match next {
				`\\`, `"` {
					decoded.write_u8(next)
				}
				`n` {
					decoded.write_u8(`\n`)
				}
				`r` {
					decoded.write_u8(`\r`)
				}
				`t` {
					decoded.write_u8(`\t`)
				}
				else {
					// Preserve unknown escapes, e.g. in hand-written Windows paths.
					decoded.write_u8(ch)
					decoded.write_u8(next)
				}
			}

			i += 2
			continue
		}
		decoded.write_u8(ch)
		i++
	}
	return none
}

fn valid_env_key(key string) bool {
	if key == '' {
		return false
	}
	for i, ch in key.bytes() {
		if ch == `_` || (ch >= `A` && ch <= `Z`) || (ch >= `a` && ch <= `z`) {
			continue
		}
		if i > 0 && ch >= `0` && ch <= `9` {
			continue
		}
		return false
	}
	return true
}

// format_env_map validates keys and emits one quoted, escaped value per line.
fn format_env_map(env_map map[string]string) !string {
	mut output := strings.new_builder(100)
	for key, value in env_map {
		if !valid_env_key(key) {
			return error('environment variable keys must match [A-Za-z_][A-Za-z0-9_]*')
		}
		escaped := value.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n').replace('\r',
			'\\r').replace('\t', '\\t')
		output.write_string('${key}="${escaped}"\n')
	}
	return output.str()
}

// format_terminal_env_map escapes additional controls only after dotenv serialization.
// Structural newlines and the serializer's existing escapes are preserved.
fn format_terminal_env_map(env_map map[string]string) !string {
	serialized := format_env_map(env_map)!
	mut output := strings.new_builder(serialized.len)
	for ch in serialized.runes() {
		if (ch < 0x20 && ch != `\n`) || ch == 0x7f {
			output.write_string('\\x${int(ch):02x}')
		} else if ch >= 0x80 && ch <= 0x9f {
			output.write_string('\\u${int(ch):04x}')
		} else {
			output.write_string(ch.str())
		}
	}
	return output.str()
}

// load_env parse the contents of the specified file to set/overload an environment variable
fn load_env(filename string, overload_env bool) ! {
	contents := read_file(filename)
	if contents == '' {
		return
	}
	env_map := parse_lines(dotenv_lines(contents), true)!
	load_env_map(env_map, overload_env)!
}

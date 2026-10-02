module vdotenv

import os
import time
import strings

// load create environment variables from the values in specified files; default to .env
// [note: Does not overwrite env variables that already exist.]
pub fn load(filenames ...string) {
	if filenames.len > 0 {
		for filename in filenames {
			load_env(filename, false)
		}
	} else {
		load_env('.env', false)
	}
}

// over_load create environment variables from specified files; default to .env
// [note: Overwrites env variables that already exist.] 環境変数を上書きする.
pub fn over_load(filenames ...string) {
	if filenames.len > 0 {
		for filename in filenames {
			load_env(filename, true)
		}
	} else {
		load_env('.env', true)
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
pub fn unmarshal(str string) map[string]string {
	return parse_contents(str)
}

// write serializes the given environment and writes it to a file.
// Invalid keys return an error without creating or overwriting the file.
pub fn write(env_map map[string]string, filename string) ! {
	contents := format_env_map(env_map)!
	os.write_file(filename, contents)!
}

// print_terminal prints the values set in .env file to the terminal
// .envファイルに記載されている環境変数に関して現在の設定状況をターミナルに表示する．
// Returns an error if a key cannot be serialized.
pub fn print_terminal() ! {
	filename := '.env'
	contents := read_file(filename)
	if contents == '' {
		return
	}
	file_env_map := parse_contents(contents)
	os_env_map := read_env_var(file_env_map.keys())
	println(format_env_map(os_env_map)!)
}

// print_file writes the values set in .env file to a file
// Returns an error if a key cannot be serialized, without creating an output file.
// .envファイルに記載されている環境変数に関して，現在の設定状況をファイルに書き出す．
pub fn print_file() ! {
	filename := '.env'
	contents := read_file(filename)
	if contents == '' {
		return
	}
	file_env_map := parse_contents(contents)
	os_env_map := read_env_var(file_env_map.keys())
	contents_to_write := format_env_map(os_env_map)!
	write_file(filename, contents_to_write)!
}

// parse writes contents of files into a format easily parsed by other systems without modifying environment
pub fn parse(include_names bool, filenames ...string) string {
	mut files := parse_files(filenames)
	mut output_builder := strings.new_builder(100)
	output_builder.write_string('{ ')
	fnames := files.keys()
	for file_ndx in 0 .. fnames.len {
		variables := files[fnames[file_ndx]].clone()
		keys := variables.keys()
		fname := fnames[file_ndx]
		if include_names {
			output_builder.write_string('/* file: ${fname} */ ')
		}
		for i in 0 .. keys.len {
			quoted_var := variables[keys[i]].replace('"', '\\"')
			output_builder.write_string('"${keys[i]}" : "${quoted_var}"')
			if i < keys.len - 1 {
				output_builder.write_string(', ')
			} else {
				output_builder.write_string('')
			}
		}
		if file_ndx < filenames.len - 1 {
			output_builder.write_string(',')
		}
		output_builder.write_string(' ')
	}
	output_builder.write_string('}')
	return output_builder.str()
}

// load_env_map sets/overwrites enviroments variables with values from env_map
fn load_env_map(env_map map[string]string, over_load bool) {
	for env in env_map.keys() {
		key := env
		value := env_map[key]
		os.setenv(key, value, over_load)
	}
}

// read_file read file contents into a string fileを読み込む
fn read_file(filename string) string {
	contents := os.read_file(filename.trim_space()) or {
		println('Failed to open ${filename}')
		return ''
	}
	return contents
}

// write_file write contents to timestamped file fileに書き出す
fn write_file(filename string, contents string) ! {
	write_filename := './${filename.trim_space()} ${time.now()}'
	os.write_file(write_filename, contents)!
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
fn parse_files(filenames []string) map[string]map[string]string {
	mut files := map[string]map[string]string{}
	if filenames.len > 0 {
		for filename in filenames {
			contents := read_file(filename)
			variables := parse_contents(contents)
			files[filename] = variables.clone()
		}
	} else {
		contents := read_file('.env')
		variables := parse_contents(contents)
		files['.env'] = variables.clone()
	}
	return files
}

// parse_contents parses the contents of a file's contents and returns a map of environment variable
// .envファイルから読み込んだcontentsをkeys and values で返却する．
fn parse_contents(contents string) map[string]string {
	lines := contents.split_into_lines()
	return parse_lines(lines)
}

// parse_lines return a map of environment variables by parsing the lines of a file
// env file から読み込んだ各行を keys and values で返却する.
fn parse_lines(lines []string) map[string]string {
	mut env_map := map[string]string{}
	for raw_line in lines {
		line := raw_line.trim_space()
		if line == '' || line.starts_with('#') {
			continue
		}
		separator := line.index('=') or { continue }
		key := line[..separator].trim_space()
		if key == '' {
			continue
		}
		value := parse_value(line[separator + 1..]) or { continue }
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
				`\\`, `"` { decoded.write_u8(next) }
				`n` { decoded.write_u8(`\n`) }
				`r` { decoded.write_u8(`\r`) }
				`t` { decoded.write_u8(`\t`) }
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
	if key.len == 0 {
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

// load_env parse the contents of the specified file to set/overload an environment variable
fn load_env(filename string, overload_env bool) {
	contents := read_file(filename)
	if contents == '' {
		return
	}
	env_map := parse_contents(contents)
	load_env_map(env_map, overload_env)
}

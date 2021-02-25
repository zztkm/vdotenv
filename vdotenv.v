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

// print_terminal prints the values set in .env file to the terminal
// .envファイルに記載されている環境変数に関して現在の設定状況をターミナルに表示する．
pub fn print_terminal() {
	filename := '.env'
	contents := read_file(filename)
	if contents == '' {
		return
	}
	file_env_map := parse_contents(contents)
	os_env_map := read_env_var(file_env_map.keys())
	println(format_env_map(os_env_map))
}

// print_file writes the values set in .env file to a file
// .envファイルに記載されている環境変数に関して，現在の設定状況をファイルに書き出す．
pub fn print_file() {
	filename := '.env'
	contents := read_file(filename)
	if contents == '' {
		return
	}
	file_env_map := parse_contents(contents)
	os_env_map := read_env_var(file_env_map.keys())
	write_file(filename, format_env_map(os_env_map))
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
			output_builder.write_string('/* file: $fname */ ')
		}
		for i in 0 .. keys.len {
			quoted_var := variables[keys[i]].replace('"', '\\"')
			output_builder.write_string('"${keys[i]}" : "$quoted_var"')
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
		println('Failed to open $filename')
		return ''
	}
	return contents
}

// write_file write contents to timestamped file fileに書き出す
fn write_file(filename string, contents string) {
	write_filename := './$filename.trim_space() $time.now()'
	os.write_file(write_filename, contents) or {
		println('Failed to open $write_filename')
		return
	}
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
	for line in lines {
		if !line.starts_with('#') && line.len > 0 {
			segments_between_hashes := line.split('#')
			mut quotes_are_open := false
			mut segments_to_keep := []string{}
			for segment in segments_between_hashes {
				if segment.count('"') == 1 || segment.count("'") == 1 {
					if quotes_are_open {
						quotes_are_open = false
						segments_to_keep << segment
					} else {
						quotes_are_open = true
					}
				}
				if segments_to_keep.len == 0 || quotes_are_open {
					segments_to_keep << segment
				}
			}
			mut new_line := segments_to_keep.join('#')
			key := new_line.split('=')[0].trim_space()
			mut value := new_line.split('=')[1].trim_space()

			// check quoted values
			if value.count('"') == 2 || value.count("'") == 2 {
				value = value.trim('"\'')
				value = value.replace('\\"', '"')
				value = value.replace('\\n', '\n')
			}
			env_map[key] = value
		}
	}
	return env_map
}

// format_env_map format key-value pairs on new lines, key=value
// keys and values で渡された値をkey=valueにフォーマットする．
fn format_env_map(env_map map[string]string) string {
	mut format_string := ''
	for key in env_map.keys() {
		format_string += '$key=${env_map[key]}\n'
	}
	return format_string
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

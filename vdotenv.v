module vdotenv

import os
import time

// note: Do not overwrite env variables that already exist.
pub fn load(filenames ...string) {
	if filenames.len > 0 {
		for filename in filenames {
			load_env(filename, false)
		}
	} else {
		load_env('.env', false)
	}
}

// 環境変数を上書きする.
pub fn over_load(filenames ...string) {
	if filenames.len > 0 {
		for filename in filenames {
			load_env(filename, true)
		}
	} else {
		load_env('.env', true)
	}
}

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

// env_mapを環境変数に読み込む
fn load_env_map(env_map map[string]string, over_load bool) {
	for env in env_map.keys() {
		key := env
		value := env_map[key]
		os.setenv(key, value, over_load)
	}
}

// fileを読み込む
fn read_file(filename string) string {
	contents := os.read_file(filename.trim_space()) or {
		println('Failed to open $filename')
		return ''
	}
	return contents
}

// fileに書き出す
fn write_file(filename, contents string) {
	write_filename := './$filename.trim_space() $time.now()'
	os.write_file(write_filename, contents) or {
		println('Failed to open $write_filename')
		return
	}
}

// 引数で渡されたキーに紐づく環境変数を読み込み keys and values で返却する.
fn read_env_var(keys []string) map[string]string {
	mut env_map := map[string]string{}
	for key in keys {
		env_map[key] = os.getenv(key)
	}
	return env_map
}

// .envファイルから読み込んだcontentsをkeys and values で返却する．
fn parse_contents(contents string) map[string]string {
	lines := contents.split_into_lines()
	return parse_lines(lines)
}

// env file から読み込んだ各行を keys and values で返却する.
fn parse_lines(lines []string) map[string]string {
	mut env_map := map[string]string{}
	for line in lines {
		key := line.split('=')[0]
		value := line.split('=')[1]
		env_map[key] = value
	}
	return env_map
}

// keys and values で渡された値をkey=valueにフォーマットする．
fn format_env_map(env_map map[string]string) string {
	mut format_string := ''
	for key in env_map.keys() {
		format_string += '$key=${env_map[key]}\n'
	}
	return format_string
}

// load env
fn load_env(filename string, overload_env bool) {
	contents := read_file(filename)
	if contents == '' {
		return
	}
	env_map := parse_contents(contents)
	load_env_map(env_map, overload_env)
}

module vdotenv

import os

// note: Do not overwrite env variables that already exist.
// 
// test
pub fn load() {
    filename := '.env'
    load_file(filename, false)
}

//環境変数を上書きする.
pub fn over_load() {
    filename := '.env'
    load_file(filename, true)
}

// .envファイルに記載されている環境変数の設定状況をターミナルに表示する
fn print_terminal() {
    filename := '.env'
    contents := os.read_file(filename.trim_space()) or {
        println('Failed to open $filename')
        return
    }
    lines := contents.split_into_lines()
    file_env_map := parse_lines(lines)
    keys := file_env_map.keys()
    os_env_map := load_env_var(keys)
    println(format_env_map(os_env_map))
}

fn load_file(filename string, over_load bool) {
    contents := os.read_file(filename.trim_space()) or {
        println('Failed to open $filename')
        return
    }
    lines := contents.split_into_lines()
    env_map := parse_lines(lines)
    for env in env_map.keys() {
        key := env
        value := env_map[key]
        os.setenv(key, value, over_load)
    }
}

// 引数で渡されたキーに紐づく環境変数を keys and values で返却する.
fn load_env_var(keys []string) map[string]string{
    mut env_map := map[string]string {}
    for key in keys {
        env_map[key] = os.getenv(key)
    }
    return env_map
}

// env file から読み込んだ値を keys and values で返却する.
fn parse_lines(lines []string) map[string]string {
    mut env_map := map[string]string{}
    for line in lines {
        key := line.split('=')[0]
        value := line.split('=')[1]
        env_map[key] = value
    }
    return env_map 
}

// keys and values で渡された値をkey=valueにフォーマットする
fn format_env_map(env_map map[string]string) string {
    mut format_string := ''
    for key in env_map.keys() {
        format_string += '$key=${env_map[key]}\n'
    }
    return format_string
}
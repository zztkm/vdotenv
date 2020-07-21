module vdotenv

import os

//.envファイルから環境変数を読み込んで設定する.
pub fn load() {
    filename := '.env'
    load_file(filename, false)
}

//環境変数を上書きする.
pub fn over_load() {
    filename := '.env'
    load_file(filename, true)
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
        // 現状は環境変数を上書きしないようにしている
        os.setenv(key, value, over_load)
    }
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
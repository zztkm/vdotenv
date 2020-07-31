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

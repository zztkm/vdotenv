module vdotenv

import os

//.envファイルから環境変数を読み込んで設定する.
pub fn load() {
        path := '.env'
        contents := os.read_file(path.trim_space()) or {
                println('Failed to open $path')
                return
        }
        lines := contents.split_into_lines()
        pairs := parse_lines(lines)
        parse_set_env(pairs)
}

// 環境変数を key&valueの組で保存.
fn parse_lines(lines []string) map[string]string {
        mut dict := map[string]string{}
        for line in lines {
                mut key := line.split('=')[0]
                mut value := line.split('=')[1]
                dict[key] = value
        }
        return dict
}

// 渡されたmapを解析して環境変数を設定する.
fn parse_set_env(pairs map[string]string) {
        for pair in pairs.keys() {
                mut key := pair
                mut value := pairs[key]
                // 現状は環境変数を上書きしないようにしている
                os.setenv(key, value, false)
        }
}
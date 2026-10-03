import json
import zztkm.vdotenv

fn main() {
	// false selects strict JSON; true adds escaped filename comments.
	// parse does not modify the process environment.
	// Paths are literal; one initial UTF-8 BOM is ignored in each file.
	// NUL keys/values return ParseError instead of being truncated.
	output := vdotenv.parse(false) or { panic(err) }
	env_map := json.decode(map[string]string, output) or { panic(err) }

	println(env_map['S3_BUCKET'])
	println(env_map['DYNAMODB_TABLE'])
}

module vdotenv

import os
import rand

/*
Sample .env file for tests:
.env
TEST=OVERLOADENV
TEST1='LOADENV'
TEST2=LOADENV
#TEST3=NOLOADENV
TEST4=NOHASH#COMMENTSTARTSHERe
TEST5=NOHASH #TEST6=NOLOADENV
TEST7 = "HASH #ENV" # COMMENT

.env.parse
WORDONE=HELLO
WORDTWO=WORLD
*/
fn test_load() {
	// loads env vars from a .env file.
	load()!
	env_var := os.getenv('TEST2')
	assert env_var == 'LOADENV'
}

fn test_load_quoted() {
	// loads env vars from a .env file.
	load()!
	env_var := os.getenv('TEST1')
	assert env_var == 'LOADENV'
}

fn test_over_load() {
	// over loads env vars from .env file.
	over_load()!
	env_var := os.getenv('TEST')
	assert env_var == 'OVERLOADENV'
}

fn test_comments_start_line() {
	// loads env vars and verifies that comments that start a line are ignored
	load()!
	env_var := os.getenv('TEST3')
	assert env_var == ''
}

fn test_comments_end_line() {
	load()!
	// loads env vars and verifies that comments are removed from the end of values
	env_var := os.getenv('TEST4')
	assert env_var == 'NOHASH'
	env_var2 := os.getenv('TEST5')
	assert env_var2 == 'NOHASH'
}

fn test_quoted_hash() {
	load()!
	// load env vars and verify comments are ignored without affecting hashes within quotes
	env_var := os.getenv('TEST7')
	assert env_var == 'HASH #ENV'
}

fn test_parse() {
	// test that returning a hash of env vars parsed from the default '.env' file
	assert parse(true)! == '{ /* file: .env */ "TEST" : "OVERLOADENV", "TEST1" : "LOADENV", "TEST2" : "LOADENV", "TEST4" : "NOHASH", "TEST5" : "NOHASH", "TEST7" : "HASH #ENV" }'
}

fn test_marshal_prevents_variable_injection() {
	env_map := {
		'USER_INPUT': 'hello\nVDOTENV_PROBE_ADMIN=enabled'
	}
	encoded := marshal(env_map)!
	decoded := unmarshal(encoded)!
	assert 'VDOTENV_PROBE_ADMIN' !in decoded
	assert decoded == env_map
	assert encoded.split_into_lines().len == 1
}

fn test_marshal_round_trips_special_values() {
	values := ['', 'plain', ' leading and trailing ', 'line\nbreak', 'carriage\rreturn',
		'windows\r\nnewline', 'tab\there', '"quoted" and \'single\'', 'C:\\path\\file',
		'literal \\n and \\r and \\t', 'trailing\\', '#hash', 'a=b=c', '"#quoted hash"',
		'backslash before quote: \\" # hash', '日本語']
	for value in values {
		env_map := {
			'VALUE': value
		}
		assert unmarshal(marshal(env_map)!)! == env_map
	}
}

fn test_marshal_uses_quoted_escaped_lines() {
	assert marshal({
		'VALUE': '\\"\n\r\t#='
	})! == 'VALUE="\\\\\\"\\n\\r\\t#="\n'
	assert marshal(map[string]string{})! == ''
}

fn test_marshal_round_trips_escape_combinations() {
	parts := ['', '\\', '"', "'", '#', '=', '\n', '\r', '\t', ' ', 'text']
	for first in parts {
		for second in parts {
			for third in parts {
				env_map := {
					'VALUE': first + second + third
				}
				assert unmarshal(marshal(env_map)!)! == env_map
			}
		}
	}
}

fn test_marshal_and_load_prevent_variable_injection() {
	directory := new_test_directory()!
	defer {
		os.rmdir_all(directory) or { panic(err) }
	}
	keys := ['USER_INPUT', 'VDOTENV_PROBE_ADMIN']
	previous_env := os.environ()
	defer {
		restore_test_environment(previous_env, keys)
	}
	for key in keys {
		os.unsetenv(key)
	}
	env_map := {
		'USER_INPUT': 'hello\nVDOTENV_PROBE_ADMIN=enabled'
	}
	filename := os.join_path(directory, 'injection.env')
	os.write_file(filename, marshal(env_map)!)!
	load(filename)!
	assert 'VDOTENV_PROBE_ADMIN' !in os.environ()
	assert os.getenv('USER_INPUT') == env_map['USER_INPUT']
	os.setenv('USER_INPUT', 'existing', true)
	load(filename)!
	assert os.getenv('USER_INPUT') == 'existing'
	over_load(filename)!
	assert os.getenv('USER_INPUT') == env_map['USER_INPUT']
	assert 'VDOTENV_PROBE_ADMIN' !in os.environ()
}

fn test_marshal_rejects_invalid_keys() {
	invalid_keys := ['', 'BAD\nINJECTED', 'BAD\rINJECTED', 'BAD=KEY', ' BAD', 'BAD ', 'BAD-KEY',
		'BAD.KEY', '1BAD', '#BAD', 'BAD"KEY', 'BAD\x00KEY', '日本語']
	for key in invalid_keys {
		mut rejected := false
		marshal({
			key: 'value'
		}) or { rejected = true }
		assert rejected, 'Expected marshal to reject invalid key'
	}
}

fn test_marshal_accepts_portable_keys() {
	env_map := {
		'_':        ''
		'_VALUE_1': 'one'
		'lower':    'two'
		'UPPER':    'three'
	}
	assert unmarshal(marshal(env_map)!)! == env_map
}

fn test_print_terminal_propagates_invalid_key_errors() {
	directory := new_test_directory()!
	previous_directory := os.getwd()
	defer {
		os.chdir(previous_directory) or { panic(err) }
		os.rmdir_all(directory) or { panic(err) }
	}
	os.chdir(directory)!
	os.write_file('.env', 'BAD-KEY=value\n')!
	mut terminal_rejected := false
	print_terminal() or { terminal_rejected = true }
	assert terminal_rejected
}

fn test_unmarshal_quoted_escapes_and_comments() {
	contents := 'VALUE="a=b # hash \\"quote\\" \\\\ literal \\n newline" # comment\n'
	assert unmarshal(contents)! == {
		'VALUE': 'a=b # hash "quote" \\ literal \n newline'
	}
	assert unmarshal("VALUE='a=b # hash' # comment\n")! == {
		'VALUE': 'a=b # hash'
	}
	assert unmarshal('VALUE=a=b=c # comment\n')! == {
		'VALUE': 'a=b=c'
	}
	assert unmarshal('VALUE="C:\\path\\file"\n')! == {
		'VALUE': 'C:\\path\\file'
	}
	assert unmarshal("VALUE='literal \\n \\t \\r \\\\'\n")! == {
		'VALUE': 'literal \\n \\t \\r \\\\'
	}
}

fn test_unmarshal_ignores_whitespace_and_indented_comments() {
	assert unmarshal(' \t\n  # comment\n\t# another comment\n VALUE = a=b=c # comment\nEMPTY=\n')! == {
		'VALUE': 'a=b=c'
		'EMPTY': ''
	}
}

fn test_print_terminal_rejects_malformed_lines() {
	directory := new_test_directory()!
	previous_directory := os.getwd()
	defer {
		os.chdir(previous_directory) or { panic(err) }
		os.rmdir_all(directory) or { panic(err) }
	}
	os.chdir(directory)!
	os.write_file('.env', 'VALID=before\nINVALID_LINE_SECRET\nAFTER=after\n')!
	mut rejected := false
	print_terminal() or {
		rejected = true
		assert err.msg().contains('line 2')
		assert !err.msg().contains('SECRET')
	}
	assert rejected, 'Expected malformed input to return a parse error'
}

fn test_unmarshal_returns_parse_errors_without_secrets() {
	malformed_lines := ['INVALID_LINE', 'INVALID_LINE_SECRET', '=SECRET_VALUE', 'TOKEN="SECRET_VALUE',
		"TOKEN='SECRET_VALUE", 'TOKEN="SECRET_VALUE" unexpected']
	for line in malformed_lines {
		for contents in [line, 'VALID=before\n \t\n # comment\n${line}\nAFTER=after\n',
			'VALID=before\r\n${line}\r\nAFTER=after\r\n'] {
			expected_line := if contents == line {
				1
			} else if contents.contains('\r\n') {
				2
			} else {
				4
			}
			mut rejected := false
			unmarshal(contents) or {
				rejected = true
				assert_test_parse_error(err, expected_line)
			}
			assert rejected, 'Expected malformed input to return a parse error'
		}
	}
	assert unmarshal('')! == map[string]string{}
	assert unmarshal(' \t\n  # comment\n')! == map[string]string{}
}

fn test_file_apis_propagate_parse_errors_without_changing_environment() {
	directory := new_test_directory()!
	previous_directory := os.getwd()
	keys := ['VDOTENV_MALFORMED_BEFORE', 'VDOTENV_MALFORMED_AFTER']
	previous_env := os.environ()
	defer {
		os.chdir(previous_directory) or { panic(err) }
		os.rmdir_all(directory) or { panic(err) }
		restore_test_environment(previous_env, keys)
	}
	os.chdir(directory)!
	malformed_lines := ['INVALID_LINE_SECRET', '=SECRET_VALUE', 'TOKEN="SECRET_VALUE',
		"TOKEN='SECRET_VALUE", 'TOKEN="SECRET_VALUE" unexpected']
	for line in malformed_lines {
		os.write_file('.env', '${keys[0]}=before\n${line}\n${keys[1]}=after\n')!
		for use_default in [false, true] {
			for key in keys {
				os.unsetenv(key)
			}
			filenames := if use_default { []string{} } else { ['.env'] }
			mut load_rejected := false
			load(...filenames) or {
				load_rejected = true
				assert_test_parse_error(err, 2)
			}
			assert load_rejected
			for key in keys {
				assert key !in os.environ()
			}
			os.setenv(keys[0], 'existing', true)
			mut overload_rejected := false
			over_load(...filenames) or {
				overload_rejected = true
				assert_test_parse_error(err, 2)
			}
			assert overload_rejected
			assert os.getenv(keys[0]) == 'existing'
			assert keys[1] !in os.environ()
			for include_names in [false, true] {
				mut parse_rejected := false
				parse(include_names, ...filenames) or {
					parse_rejected = true
					assert_test_parse_error(err, 2)
				}
				assert parse_rejected
			}
		}
	}
}

fn test_multifile_apis_stop_at_malformed_file() {
	directory := new_test_directory()!
	keys := ['VDOTENV_MALFORMED_FIRST', 'VDOTENV_MALFORMED_SECOND', 'VDOTENV_MALFORMED_THIRD']
	previous_env := os.environ()
	defer {
		os.rmdir_all(directory) or { panic(err) }
		restore_test_environment(previous_env, keys)
	}
	first := os.join_path(directory, 'first.env')
	second := os.join_path(directory, 'second.env')
	third := os.join_path(directory, 'third.env')
	os.write_file(first, '${keys[0]}=first\n')!
	os.write_file(second, '${keys[1]}=second\nINVALID_LINE_SECRET\n')!
	os.write_file(third, '${keys[2]}=third\n')!
	for overwrite in [false, true] {
		for key in keys {
			os.unsetenv(key)
		}
		mut rejected := false
		if overwrite {
			over_load(first, second, third) or {
				rejected = true
				assert_test_parse_error(err, 2)
			}
		} else {
			load(first, second, third) or {
				rejected = true
				assert_test_parse_error(err, 2)
			}
		}
		assert rejected
		// Earlier files remain applied, but the malformed file is not partially loaded.
		assert os.getenv(keys[0]) == 'first'
		assert keys[1] !in os.environ()
		assert keys[2] !in os.environ()
	}
	mut rejected := false
	parse(true, first, second, third) or {
		rejected = true
		assert_test_parse_error(err, 2)
	}
	assert rejected
}

fn assert_test_parse_error(err IError, expected_line int) {
	assert err is ParseError
	if err is ParseError {
		assert err.line == expected_line
		assert err.reason != ''
	}
	assert err.msg().contains('line ${expected_line}')
	assert !err.msg().contains('SECRET')
	assert !err.msg().contains('TOKEN')
	assert !err.msg().contains('INVALID_LINE')
}

fn new_test_directory() !string {
	directory := os.join_path(os.temp_dir(), 'vdotenv-${rand.ulid()}')
	os.mkdir(directory)!
	return directory
}

fn restore_test_environment(previous map[string]string, keys []string) {
	for key in keys {
		if key in previous {
			os.setenv(key, previous[key], true)
		} else {
			os.unsetenv(key)
		}
	}
}

fn test_parse_multifiles() {
	// test that returning a hash of env vars parsed from a variable number of files
	assert parse(true, '.env', '.env.parse')! == '{ /* file: .env */ "TEST" : "OVERLOADENV", "TEST1" : "LOADENV", "TEST2" : "LOADENV", "TEST4" : "NOHASH", "TEST5" : "NOHASH", "TEST7" : "HASH #ENV", /* file: .env.parse */ "WORDONE" : "HELLO", "WORDTWO" : "WORLD" }'
}

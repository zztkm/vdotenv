module vdotenv

import json
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

fn test_parse_json_prevents_key_injection() {
	directory := new_test_directory()!
	defer {
		os.rmdir_all(directory) or { panic(err) }
	}
	filename := os.join_path(directory, 'injection.env')
	key := 'A" : "safe", "ROLE'
	os.write_file(filename, '${key}=admin\n')!
	output := parse(false, filename)!
	decoded := json.decode(map[string]string, output) or {
		assert false, 'Expected valid JSON: ${output}'
		return
	}
	assert 'ROLE' !in decoded
	assert decoded == {
		key: 'admin'
	}
}

fn test_parse_json_round_trips_special_keys() {
	directory := new_test_directory()!
	defer {
		os.rmdir_all(directory) or { panic(err) }
	}
	filename := os.join_path(directory, 'keys.env')
	for key in ['A"KEY', 'A\\KEY', 'A\tKEY'] {
		os.write_file(filename, '${key}=value\n')!
		output := parse(false, filename)!
		assert output.contains(json.encode(key)), 'Expected a JSON-escaped key: ${output}'
		decoded := json.decode(map[string]string, output) or {
			assert false, 'Expected valid JSON: ${output}'
			return
		}
		assert decoded == {
			key: 'value'
		}
	}
}

fn test_parse_json_round_trips_backslashes() {
	directory := new_test_directory()!
	defer {
		os.rmdir_all(directory) or { panic(err) }
	}
	filename := os.join_path(directory, 'values.env')
	for value in ['literal \\n', 'C:\\path\\file', 'trailing\\', '\\"quoted"'] {
		env_map := {
			'VALUE': value
		}
		os.write_file(filename, marshal(env_map)!)!
		output := parse(false, filename)!
		decoded := json.decode(map[string]string, output) or {
			assert false, 'Expected valid JSON: ${output}'
			return
		}
		assert decoded == env_map
		assert output.contains(json.encode(value))
	}
}

fn test_parse_json_escapes_control_values() {
	directory := new_test_directory()!
	defer {
		os.rmdir_all(directory) or { panic(err) }
	}
	filename := os.join_path(directory, 'controls.env')
	for value in ['tab\there', 'line\nbreak', 'carriage\rreturn', '\x01\x08\x0c\x1f'] {
		env_map := {
			'VALUE': value
		}
		os.write_file(filename, marshal(env_map)!)!
		output := parse(false, filename)!
		assert output.contains(json.encode(value)), 'Expected a JSON-escaped value: ${output}'
		decoded := json.decode(map[string]string, output) or {
			assert false, 'Expected valid JSON: ${output}'
			return
		}
		assert decoded == env_map
	}
}

fn test_parse_names_escape_comment_delimiters() {
	directory := new_test_directory()!
	defer {
		os.rmdir_all(directory) or { panic(err) }
	}
	filename := os.join_path(directory, 'break*', 'quoted"\\\n\t.env')
	os.mkdir_all(os.dir(filename))!
	os.write_file(filename, 'VALUE=safe\n')!
	output := parse(true, filename)!
	comment_start := output.index('/* file: ') or { panic('Expected a file comment') }
	comment_end := output.index(' */') or { panic('Expected a closed file comment') }
	label := output[comment_start + '/* file: '.len..comment_end]
	assert !label.contains('*/'), 'Filename must not terminate the comment'
	assert !label.contains('\n') && !label.contains('\t')
	// Labels are JSON string contents, with slashes escaped to protect comment delimiters.
	decoded_name := json.decode(map[string]string, '{"filename":"${label}"}') or {
		assert false, 'Expected a JSON-escaped filename label'
		return
	}
	assert decoded_name['filename'] == filename
	json_output := output[..comment_start] + output[comment_end + ' */'.len..]
	decoded := json.decode(map[string]string, json_output) or {
		assert false, 'Expected valid JSON after removing the file comment: ${json_output}'
		return
	}
	assert decoded == {
		'VALUE': 'safe'
	}
}

fn test_parse_json_empty_files_do_not_add_commas() {
	directory := new_test_directory()!
	defer {
		os.rmdir_all(directory) or { panic(err) }
	}
	empty := os.join_path(directory, 'empty.env')
	full := os.join_path(directory, 'full.env')
	os.write_file(empty, ' # comment\n')!
	os.write_file(full, 'VALUE=safe\n')!
	for filenames in [[empty, full], [full, empty], [empty, full, empty]] {
		output := parse(false, ...filenames)!
		decoded := json.decode(map[string]string, output) or {
			assert false, 'Expected valid JSON with empty files: ${output}'
			return
		}
		assert decoded == {
			'VALUE': 'safe'
		}
	}
}

fn test_parse_round_trips_normal_values_and_preserves_environment() {
	directory := new_test_directory()!
	defer {
		os.rmdir_all(directory) or { panic(err) }
	}
	filename := os.join_path(directory, 'normal.env')
	env_map := {
		'_':           ''
		'lower_1':     'plain'
		'UPPER':       ' leading and trailing '
		'UNICODE':     '日本語 😀'
		'PUNCTUATION': '"quoted" and \'single\' # hash = equal /* not a file comment */'
	}
	os.write_file(filename, marshal(env_map)!)!
	previous_env := os.environ()
	for include_names in [false, true] {
		output := parse(include_names, filename)!
		assert decode_test_parse_output(output, if include_names { [filename] } else { []string{} }) == env_map
		assert os.environ() == previous_env
	}
}

fn test_unmarshal_and_parse_preserve_permissive_keys() {
	directory := new_test_directory()!
	defer {
		os.rmdir_all(directory) or { panic(err) }
	}
	filename := os.join_path(directory, 'keys.env')
	for key in ['A"KEY', 'A\\KEY', 'A\tKEY', 'A-KEY', 'A.KEY', '1KEY', '日本語'] {
		contents := ' ${key} = value\n'
		expected := {
			key: 'value'
		}
		assert unmarshal(contents)! == expected
		os.write_file(filename, contents)!
		for include_names in [false, true] {
			output := parse(include_names, filename)!
			assert decode_test_parse_output(output, if include_names {
				[filename]
			} else {
				[]string{}
			}) == expected
		}
	}
	// Physical line breaks cannot occur inside keys; they delimit dotenv lines.
	for key in ['BAD\nKEY', 'BAD\rKEY', 'BAD\r\nKEY'] {
		contents := '${key}=value\n'
		mut string_rejected := false
		unmarshal(contents) or {
			string_rejected = true
			assert_test_parse_error(err, 1)
		}
		assert string_rejected
		os.write_file(filename, contents)!
		for include_names in [false, true] {
			mut file_rejected := false
			parse(include_names, filename) or {
				file_rejected = true
				assert_test_parse_error(err, 1)
			}
			assert file_rejected
		}
	}
}

fn test_parse_empty_default_and_multifile_json() {
	directory := new_test_directory()!
	previous_directory := os.getwd()
	defer {
		os.chdir(previous_directory) or { panic(err) }
		os.rmdir_all(directory) or { panic(err) }
	}
	os.chdir(directory)!
	os.write_file('.env', '')!
	os.write_file('empty.env', ' # comment\n')!
	os.write_file('first.env', 'SHARED=first\nFIRST=one\n')!
	os.write_file('last.env', 'SHARED=last\nLAST=two\n')!
	for include_names in [false, true] {
		default_comments := if include_names { ['.env'] } else { []string{} }
		assert decode_test_parse_output(parse(include_names)!, default_comments) == map[string]string{}
		os.write_file('.env', 'DEFAULT=value\n')!
		assert decode_test_parse_output(parse(include_names)!, default_comments) == {
			'DEFAULT': 'value'
		}
		os.write_file('.env', '')!
		for filenames in [['empty.env'], ['empty.env', 'empty.env'],
			['empty.env', 'first.env', 'empty.env', 'last.env', 'empty.env']] {
			output := parse(include_names, ...filenames)!
			decoded := decode_test_parse_output(output, if include_names {
				filenames
			} else {
				[]string{}
			})
			if 'first.env' in filenames {
				assert decoded.len == 3
				assert decoded['FIRST'] == 'one'
				assert decoded['LAST'] == 'two'
				// Duplicate-name resolution is decoder-specific; preserve the existing order.
				assert decoded['SHARED'] in ['first', 'last']
				assert output.count('"SHARED"') == 2
				first_index := output.index('"SHARED" : "first"') or { panic(err) }
				last_index := output.index('"SHARED" : "last"') or { panic(err) }
				assert first_index < last_index
			} else {
				assert decoded == map[string]string{}
			}
		}
	}
}

fn test_parse_names_preserve_comment_markers_and_unicode() {
	directory := new_test_directory()!
	mut filenames := []string{}
	defer {
		// rmdir_all normalizes backslashes; remove these literal filenames directly first.
		for filename in filenames {
			os.rm(filename) or { panic(err) }
		}
		os.rmdir_all(directory) or { panic(err) }
	}
	nested := os.join_path(directory, 'break*')
	os.mkdir_all(nested)!
	for basename in ['*markers*.env', 'literal\\u002f.env', '日本語.env', '"quoted"\n\t.env'] {
		// Do not use join_path for the basename: it normalizes literal backslashes.
		filename := nested + os.path_separator + basename
		filenames << filename
		os.write_file(filename, 'VALUE="line\\n\\t\\\\\\""\n')!
		output := parse(true, filename)!
		assert output.count('/*') == 1
		assert output.count('*/') == 1
		assert !output.contains('\n') && !output.contains('\t')
		assert decode_test_parse_output(output, [filename]) == unmarshal(os.read_file(filename)!)!
	}
}

fn decode_test_parse_output(output string, filenames []string) map[string]string {
	mut json_output := output
	for filename in filenames {
		encoded_name := json.encode(filename)
		label := encoded_name[1..encoded_name.len - 1].replace('/', '\\u002f')
		json_output = json_output.replace('/* file: ${label} */ ', '')
	}
	return json.decode(map[string]string, json_output) or {
		assert false, 'Expected valid JSON after removing file comments: ${json_output}'
		map[string]string{}
	}
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

module vdotenv

import os

/*
Sample .env file for tests:

TEST=OVERLOADENV
TEST2=LOADENV
#TEST3=NOLOADENV
TEST4=NOHASH#COMMENTSTARTSHERe
TEST5=NOHASH #TEST6=NOLOADENV
TEST7 = "HASH #ENV" # COMMENT
*/
fn test_load() {
	// loads env vars from a .env file.
	load()
	env_var := os.getenv('TEST2')
	assert env_var == 'LOADENV'
}

fn test_over_load() {
	// over loads env vars from .env file.
	over_load()
	env_var := os.getenv('TEST')
	assert env_var == 'OVERLOADENV'
}

fn test_comments_start_line() {
	// loads env vars and verifies that comments that start a line are ignored
	load()
	env_var := os.getenv('TEST3')
	assert env_var == ''
}

fn test_comments_end_line() {
	load()
	// loads env vars and verifies that comments are removed from the end of values
	env_var := os.getenv('TEST4')
	assert env_var == 'NOHASH'
	env_var2 := os.getenv('TEST5')
	assert env_var2 == 'NOHASH'
}

fn test_quoted_hash() {
	load()
	// load env vars and verify comments are ignored without affecting hashes within quotes
	env_var := os.getenv('TEST7')
	assert env_var == '\"HASH #ENV\"'
}

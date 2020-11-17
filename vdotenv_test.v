module vdotenv

import os

/*
Sample .env file for tests:

#TEST3=NOLOADENV
TEST2=LOADENV #TEST4=NOLOADENV
TEST=OVERLOADENV
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

fn test_comments() {
	// loads env vars and verifies that comments that start a line
	// or have a space followed by # (' #') are ignored
	load()
	env_var := os.getenv('TEST3')
	assert env_var == ''

	env_var2 := os.getenv('TEST4')
	assert env_var2 == ''
}

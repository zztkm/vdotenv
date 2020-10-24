module vdotenv

import os

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

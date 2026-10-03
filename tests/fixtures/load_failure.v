import os
import vdotenv

#flag -I @VMODROOT/tests/fixtures
#include "setenv_failure.h"

fn main() {
	if os.args.len > 1 && os.args[1] == 'overwrite' {
		vdotenv.over_load() or {
			eprintln(err.msg())
			exit(1)
		}
	} else {
		vdotenv.load() or {
			eprintln(err.msg())
			exit(1)
		}
	}
}

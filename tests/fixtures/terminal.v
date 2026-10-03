import vdotenv

fn main() {
	vdotenv.print_terminal() or {
		eprintln(err.msg())
		exit(1)
	}
}

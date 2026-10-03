"""Inspect captured stdout bytes without sending control sequences to a terminal."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
KEY = "VDOTENV_TERMINAL_VALUE"


class TerminalOutputTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.build = tempfile.TemporaryDirectory(prefix="vdotenv-terminal-")
        cls.addClassCleanup(cls.build.cleanup)
        cls.program = Path(cls.build.name) / "terminal"
        subprocess.run(
            ["v", "-path", f"@vlib|{ROOT.parent}", "-o", str(cls.program),
             str(ROOT / "tests/fixtures/terminal.v")],
            cwd=ROOT, check=True, capture_output=True,
        )

    def capture(self, value):
        with tempfile.TemporaryDirectory() as directory:
            Path(directory, ".env").write_text(f"{KEY}=placeholder\n")
            env = os.environ.copy()
            env[KEY] = value
            return subprocess.run([self.program], cwd=directory, env=env,
                                  capture_output=True)

    def test_esc_sequences_are_visible_text(self):
        result = self.capture("\x1b[2J\x1b[Hspoofed")
        self.assertEqual(result.returncode, 0)
        self.assertNotIn(b"\x1b", result.stdout)
        self.assertIn(b"\\x1b[2J\\x1b[Hspoofed", result.stdout)

    def test_c0_del_and_c1_controls_are_visible_text(self):
        # NUL cannot occur in process environment values; cover every other C0 byte.
        controls = "".join(chr(n) for n in list(range(1, 32)) + list(range(127, 160)))
        result = self.capture(controls + "日本語 😀")
        self.assertEqual(result.returncode, 0)
        for n in list(range(1, 32)) + list(range(127, 160)):
            if n == 10:
                self.assertEqual(result.stdout.count(b"\n"), 2)  # line + println
            else:
                self.assertNotIn(chr(n).encode(), result.stdout)
        self.assertIn(b"\\x01", result.stdout)
        self.assertIn(b"\\x7f", result.stdout)
        self.assertIn(b"\\u009b", result.stdout)
        self.assertIn("日本語 😀".encode(), result.stdout)


if __name__ == "__main__":
    unittest.main()

"""Exercise public loading APIs with a deterministic OS setter failure."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class SetenvFailureTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.build = tempfile.TemporaryDirectory(prefix="vdotenv-setenv-")
        cls.addClassCleanup(cls.build.cleanup)
        cls.program = Path(cls.build.name) / "load_failure"
        subprocess.run(
            ["v", "-path", f"@vlib|{ROOT.parent}", "-o", str(cls.program),
             str(ROOT / "tests/fixtures/load_failure.v")],
            cwd=ROOT, check=True, capture_output=True,
        )

    def test_setter_failure_is_reported(self):
        for mode in ["load", "overwrite"]:
            with self.subTest(mode=mode), tempfile.TemporaryDirectory() as directory:
                Path(directory, ".env").write_text("VDOTENV_FORCE_FAILURE=SECRET_VALUE\n")
                env = os.environ.copy()
                env.pop("VDOTENV_FORCE_FAILURE", None)
                result = subprocess.run([self.program, mode], cwd=directory, env=env,
                                        capture_output=True)
                self.assertEqual(result.returncode, 1, "OS failure must reach the caller")
                self.assertNotIn(b"SECRET_VALUE", result.stderr)
                self.assertNotIn(b"VDOTENV_FORCE_FAILURE", result.stderr)


if __name__ == "__main__":
    unittest.main()

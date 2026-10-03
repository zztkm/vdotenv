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
        modules = Path(cls.build.name) / "modules"
        modules.mkdir()
        (modules / "vdotenv").symlink_to(ROOT, target_is_directory=True)
        subprocess.run(
            ["v", "-path", f"@vlib|{modules}", "-o", str(cls.program),
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

    def test_load_preserves_existing_values_including_empty(self):
        for value in ["existing", ""]:
            with self.subTest(value=value), tempfile.TemporaryDirectory() as directory:
                Path(directory, ".env").write_text("VDOTENV_FORCE_FAILURE=SECRET_VALUE\n")
                env = os.environ.copy()
                env["VDOTENV_FORCE_FAILURE"] = value
                result = subprocess.run([self.program, "load"], cwd=directory, env=env,
                                        capture_output=True)
                self.assertEqual(result.returncode, 0)
                self.assertEqual(result.stdout, (value + "\n").encode())
                result = subprocess.run([self.program, "overwrite"], cwd=directory, env=env,
                                        capture_output=True)
                self.assertEqual(result.returncode, 1)


if __name__ == "__main__":
    unittest.main()

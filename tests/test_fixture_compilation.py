"""Verify fixture compilation in GitHub Actions' nested checkout layout."""
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class FixtureCompilationTests(unittest.TestCase):
    def test_nested_checkout_runs_public_api_fixtures(self):
        with tempfile.TemporaryDirectory(prefix="vdotenv-nested-") as directory:
            checkout = Path(directory) / "vdotenv" / "vdotenv"
            checkout.mkdir(parents=True)
            for filename in ["vdotenv.v", "v.mod"]:
                shutil.copy2(ROOT / filename, checkout)
            shutil.copytree(ROOT / "tests/fixtures", checkout / "tests/fixtures")
            # Copy only these suites so this regression cannot recurse into itself.
            for filename in ["test_terminal_output.py", "test_setenv_failure.py"]:
                shutil.copy2(ROOT / "tests" / filename, checkout / "tests" / filename)
            result = subprocess.run(
                [sys.executable, "-m", "unittest", "discover", "-s", "tests",
                 "-p", "test_*.py"], cwd=checkout, capture_output=True,
            )
            self.assertEqual(result.returncode, 0,
                             (result.stdout + result.stderr).decode(errors="replace"))


if __name__ == "__main__":
    unittest.main()

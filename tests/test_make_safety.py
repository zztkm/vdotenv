"""Run destructive developer commands only in disposable repository copies."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class MakeSafetyTests(unittest.TestCase):
    def setUp(self):
        self.scratch = tempfile.TemporaryDirectory(prefix="vdotenv-make-")
        self.addCleanup(self.scratch.cleanup)
        self.root = Path(self.scratch.name)
        shutil.copy2(ROOT / "Makefile", self.root)
        shutil.copytree(ROOT / "testdata", self.root / "testdata")
        for filename in ["vdotenv.v", "vdotenv_test.v", "v.mod"]:
            shutil.copy2(ROOT / filename, self.root)
        tools = self.root / "bin"
        tools.mkdir()
        compiler = tools / "v"
        compiler.write_text('#!/bin/sh\nexit "${VDOTENV_TEST_EXIT:-0}"\n')
        compiler.chmod(0o755)
        self.env = os.environ.copy()
        self.env["PATH"] = str(tools) + os.pathsep + self.env["PATH"]

    def create_local_files(self):
        for filename in [".env", ".env.parse"]:
            path = self.root / filename
            path.write_bytes(b"LOCAL_SECRET=must_survive\n")
            path.chmod(0o600)
            os.utime(path, ns=(1_600_000_000_000_000_000, 1_600_000_000_000_000_000))
        return self.snapshot()

    def snapshot(self):
        result = {}
        for filename in [".env", ".env.parse"]:
            path = self.root / filename
            if path.exists():
                stat = path.stat()
                result[filename] = (path.read_bytes(), stat.st_mode, stat.st_mtime_ns,
                                    stat.st_ino, stat.st_uid, stat.st_gid)
        return result

    def run_make(self, target, failure=False):
        self.env["VDOTENV_TEST_EXIT"] = "1" if failure else "0"
        return subprocess.run(["make", target], cwd=self.root, env=self.env,
                              capture_output=True)

    def test_success_preserves_local_files(self):
        before = self.create_local_files()
        self.assertEqual(self.run_make("test").returncode, 0)
        self.assertEqual(self.snapshot(), before)

    def test_failure_preserves_local_files(self):
        before = self.create_local_files()
        self.assertNotEqual(self.run_make("test", failure=True).returncode, 0)
        self.assertEqual(self.snapshot(), before)

    def test_clean_preserves_local_files(self):
        before = self.create_local_files()
        self.assertEqual(self.run_make("clean").returncode, 0)
        self.assertEqual(self.snapshot(), before)


if __name__ == "__main__":
    unittest.main()

"""
Common code for unit testing of rules generated with Snakemake 9.20.0.
"""

import os
from pathlib import Path
from subprocess import check_output, PIPE


cmp_cmds = {
    ".gz":  ["zcmp"],
    ".bz2": ["bzcmp"],
    ".xz":  ["xzcmp"],
    ".bam": ["samtools", "view", "--no-header"],
    ".tsv": ["diff", "--ignore-matching-lines=^#"],
    ".csv": ["diff", "--ignore-matching-lines=^#"],
    ".sam": None,
    ".png": None,
    ".pdf": None,
    ".rds": None,
    ".html": None,
    ".log": None,
}


class OutputChecker:
    def __init__(self, data_path, expected_path, workdir):
        self.data_path = data_path
        self.expected_path = expected_path
        self.workdir = workdir

    def check(self, cmp_cmds = cmp_cmds):
        # Input files
        input_files = set(
            (Path(path) / f).relative_to(self.data_path)
            for path, subdirs, files in os.walk(self.data_path)
            for f in files
        )
        # Workdir files (ignoring '.snakemake/' and 'config/' folders)
        workdir_files = set(
            (Path(path) / f).relative_to(self.workdir)
            for path, subdirs, files in os.walk(self.workdir)
            for f in files
            if "/.snakemake" not in path and "/config" not in path
        )
        # Expected files
        expected_files = set(
            (Path(path) / f).relative_to(self.expected_path)
            for path, subdirs, files in os.walk(self.expected_path)
            for f in files
        )

        assert expected_files.issubset(
            workdir_files
        ), f"Output files missing: {expected_files - workdir_files}"

        # Compare output and expected files
        for f in expected_files:
            self.compare_files(self.expected_path / f, self.workdir / f, cmp_cmds)

    def compare_files(self, expected_file, generated_file, cmp_cmds):
        cmd = cmp_cmds.get(expected_file.suffix, ["cmp"])
        if cmd is None:
            return
        check_output(cmd + [str(expected_file), str(generated_file)], stderr=PIPE)

import json
import shutil
import sys
import tempfile
from pathlib import Path
from subprocess import check_output

sys.path.insert(0, str(Path(__file__).parent))

RULE = "make_igv_genome"
data_path = Path(__file__).parent / RULE / "data"
SNAKEFILE = Path(__file__).parent.parent.parent / "Snakefile"

# The JSON descriptor is a deterministic, human-readable text file (unlike
# the old zip archive, which carried non-deterministic timestamp/order
# metadata), so this checks descriptor content directly via json.loads
# rather than shelling out to inspect an archive.


def test_make_igv_genome(conda_prefix):
    with tempfile.TemporaryDirectory() as tmpdir:
        workdir = Path(tmpdir)
        shutil.copytree(data_path, workdir, dirs_exist_ok=True)
        shutil.copytree(Path(__file__).parent / RULE / "config", workdir / "config")
        check_output(
            [
                "snakemake",
                "results/mini.json",
                "--snakefile",
                str(SNAKEFILE),
                "--forceall",
                "--notemp",
                "--use-conda",
                "--conda-prefix",
                str(Path.home() / ".snakemake/conda"),
                "--allowed-rules",
                RULE,
                "--cores",
                "4",
                "--configfile",
                str(workdir / "config" / "config.yaml"),
                "--directory",
                str(workdir),
            ]
            + conda_prefix
        )
        genome = workdir / "results" / "mini.json"
        assert genome.exists()

        descriptor = json.loads(genome.read_text())
        assert descriptor["id"] == "MiniGenome"
        assert descriptor["name"] == "Mini Genome"
        assert descriptor["fastaURL"] == "../mini.fasta"
        assert descriptor["indexURL"] == "../mini.fasta.fai"
        assert descriptor["tracks"][0]["name"] == "Genes"
        assert descriptor["tracks"][0]["url"] == "../mini.gff"
        assert descriptor["tracks"][0]["format"] == "gff"
        assert descriptor["tracks"][0]["indexed"] is False

        assert (workdir / "mini.fasta.fai").exists()
        assert not (workdir / "results" / "mini.fasta").exists()

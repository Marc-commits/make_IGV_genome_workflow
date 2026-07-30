import shutil
import sys
import tempfile
from pathlib import Path
from subprocess import check_output

sys.path.insert(0, str(Path(__file__).parent))

RULE = "make_igv_genome"
data_path = Path(__file__).parent / RULE / "data"
SNAKEFILE = Path(__file__).parent.parent.parent / "Snakefile"

# The .genome archive is a zip (non-deterministic byte-for-byte across runs
# due to zip's own timestamp/order metadata), so this checks archive
# contents rather than a byte-identical expected fixture -- same pragmatic
# approach used for the binary bowtie2 index in the sibling
# bowtie2_build_index_workflow module.


def test_make_igv_genome(conda_prefix):
    with tempfile.TemporaryDirectory() as tmpdir:
        workdir = Path(tmpdir)
        shutil.copytree(data_path, workdir, dirs_exist_ok=True)
        shutil.copytree(Path(__file__).parent / RULE / "config", workdir / "config")
        check_output(
            [
                "snakemake",
                "results/mini.genome",
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
        genome = workdir / "results" / "mini.genome"
        assert genome.exists()

        listing = check_output(["unzip", "-l", str(genome)], text=True)
        assert "property.txt" in listing
        assert "mini.fasta" in listing
        assert "mini.fasta.fai" in listing
        assert "mini.gff" in listing

        properties = check_output(["unzip", "-p", str(genome), "property.txt"], text=True)
        assert "id=MiniGenome" in properties
        assert "name=Mini Genome" in properties
        assert "geneFile=mini.gff" in properties
        assert "sequenceLocation=mini.fasta" in properties

        integrity = check_output(["unzip", "-t", str(genome)], text=True)
        assert "No errors detected" in integrity

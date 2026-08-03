#!/usr/bin/env bash
#
# make_igv_genome.sh - build an IGV JSON genome descriptor from a FASTA +
# gene file.
#
# Version: 2.0.0
# Author:  Marc Broghammer
# Email:   marc.broghammer@gmx.de
#
# Vendored from bash_scripts/make_IGV_genome (commit 8c2a815); the JSON
# descriptor rewrite in 2.0.0 is a first-party change in this repo, no
# longer a straight passthrough of that source.
#
# Idempotent, side-effect-free beyond the documented .fai generation: reads
# only the inputs given, writes only the requested output file plus (unless
# --fai is given) a .fai index beside the input FASTA.

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_NAME
readonly VERSION="2.0.0"

usage() {
	cat <<EOF
${SCRIPT_NAME} v${VERSION}

Build an IGV flat JSON genome descriptor from a FASTA file and a gene
annotation file (GFF/GFF3/GTF/BED). Handles fasta indexing and writes a
JSON file referencing the FASTA, its .fai index, and the gene file.

Usage:
  ${SCRIPT_NAME} -f FASTA -g GENEFILE -o OUTPUT.json [options]

Required:
  -f, --fasta FILE       Genome FASTA file
  -g, --genefile FILE    Gene annotation file (.gff/.gff3/.gtf/.bed)
  -o, --output FILE      Output .json genome descriptor path

Options:
  -i, --id ID            Genome id (default: output basename without .json)
  -n, --name NAME        Genome display name (default: same as --id)
      --fai FILE         Reuse an existing .fai index instead of generating one
      --force            Overwrite OUTPUT if it already exists
  -h, --help             Show this help and exit
  -v, --version, -V     Show version and exit

Example:
  ${SCRIPT_NAME} -f genome.fasta -g genes.gff -o MyGenome.json \\
      --id MyGenome --name "My Organism"

Notes:
  - This script does not copy the FASTA or gene file. The generated JSON
    references them via a path relative to the descriptor's own directory
    (falling back to an absolute path if they live outside that tree), so
    the FASTA/gene file must remain in place at the referenced location for
    IGV to load them.
  - Unless --fai is given, a .fai index is generated next to the given
    FASTA (via samtools faidx) -- the standard samtools convention of an
    index living beside its source file. The FASTA must be writable at its
    location.
EOF
}

die() {
	echo "${SCRIPT_NAME}: error: $*" >&2
	exit 1
}

require_cmd() {
	command -v "$1" >/dev/null 2>&1 || die "required command '$1' not found (install it, e.g. via apt)"
}

fasta=""
genefile=""
output=""
genome_id=""
genome_name=""
fai=""
force=0

while [[ $# -gt 0 ]]; do
	case "$1" in
	-f | --fasta)
		fasta="$2"
		shift 2
		;;
	-g | --genefile)
		genefile="$2"
		shift 2
		;;
	-o | --output)
		output="$2"
		shift 2
		;;
	-i | --id)
		genome_id="$2"
		shift 2
		;;
	-n | --name)
		genome_name="$2"
		shift 2
		;;
	--fai)
		fai="$2"
		shift 2
		;;
	--force)
		force=1
		shift
		;;
	-h | --help)
		usage
		exit 0
		;;
	-v | --version | -V)
		echo "${SCRIPT_NAME} v${VERSION}"
		exit 0
		;;
	*) die "unknown argument: $1 (see --help)" ;;
	esac
done

[[ -n "${fasta}" ]] || die "-f/--fasta is required"
[[ -n "${genefile}" ]] || die "-g/--genefile is required"
[[ -n "${output}" ]] || die "-o/--output is required"

[[ -f "${fasta}" ]] || die "fasta file not found: ${fasta}"
[[ -f "${genefile}" ]] || die "gene file not found: ${genefile}"
[[ -n "${fai}" ]] && { [[ -f "${fai}" ]] || die "fai index not found: ${fai}"; }

if [[ -e "${output}" ]] && [[ "${force}" -ne 1 ]]; then
	die "output already exists: ${output} (use --force to overwrite)"
fi

require_cmd python3
[[ -n "${fai}" ]] || require_cmd samtools

output_base="$(basename "${output}")"
[[ -n "${genome_id}" ]] || genome_id="${output_base%.json}"
[[ -n "${genome_name}" ]] || genome_name="${genome_id}"

fai_path="${fasta}.fai"
if [[ -n "${fai}" ]]; then
	fai_path="${fai}"
else
	samtools faidx "${fasta}"
fi

output_dir="$(dirname "${output}")"
mkdir -p "${output_dir}"

python3 - "${fasta}" "${fai_path}" "${genefile}" "${output}" "${genome_id}" "${genome_name}" <<'PYEOF'
import json
import os
import sys

fasta, fai_path, genefile, output, genome_id, genome_name = sys.argv[1:7]

out_dir = os.path.dirname(os.path.abspath(output)) or "."


def rel(path):
    return os.path.relpath(os.path.abspath(path), start=out_dir)


ext = os.path.splitext(genefile)[1].lstrip(".").lower()
fmt = {"gff3": "gff3", "gff": "gff", "gtf": "gtf", "bed": "bed"}.get(ext)
if fmt is None:
    sys.exit(
        f"make_igv_genome.sh: error: unsupported gene file extension "
        f"'.{ext}' (expected .gff/.gff3/.gtf/.bed)"
    )

descriptor = {
    "id": genome_id,
    "name": genome_name,
    "fastaURL": rel(fasta),
    "indexURL": rel(fai_path),
    "tracks": [
        {
            "name": "Genes",
            "url": rel(genefile),
            "format": fmt,
            "indexed": False,
        }
    ],
}

tmp_output = output + ".tmp"
with open(tmp_output, "w") as fh:
    json.dump(descriptor, fh, indent=2)
    fh.write("\n")
os.replace(tmp_output, output)
PYEOF

echo "wrote: ${output}"

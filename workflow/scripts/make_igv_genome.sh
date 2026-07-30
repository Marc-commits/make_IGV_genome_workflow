#!/usr/bin/env bash
#
# make_igv_genome.sh - build an IGV .genome archive from a FASTA + gene file.
#
# Version: 1.0.0
# Author:  Marc Broghammer
# Email:   marc.broghammer@gmx.de
#
# Vendored from bash_scripts/make_IGV_genome (commit 8c2a815) and wrapped in
# a Snakemake rule for this module -- logic unchanged from the source.
#
# Idempotent, side-effect-free: reads only the inputs given, writes only the
# requested output file (never overwrites without --force).

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_NAME
readonly VERSION="1.0.0"

usage() {
	cat <<EOF
${SCRIPT_NAME} v${VERSION}

Build an IGV .genome archive (zip) from a FASTA file and a gene annotation
file (GFF/GTF/BED). Handles fasta indexing and packages everything IGV
expects (property.txt, sequence, index, gene file) into one archive.

Usage:
  ${SCRIPT_NAME} -f FASTA -g GENEFILE -o OUTPUT.genome [options]

Required:
  -f, --fasta FILE       Genome FASTA file
  -g, --genefile FILE    Gene annotation file (.gff/.gff3/.gtf/.bed)
  -o, --output FILE      Output .genome archive path

Options:
  -i, --id ID            Genome id (default: output basename without .genome)
  -n, --name NAME        Genome display name (default: same as --id)
      --fai FILE         Reuse an existing .fai index instead of generating one
      --force            Overwrite OUTPUT if it already exists
      --keep-tmp         Do not delete the staging directory (prints its path)
  -h, --help             Show this help and exit
  -v, --version, -V     Show version and exit

Example:
  ${SCRIPT_NAME} -f genome.fasta -g genes.gff -o MyGenome.genome \\
      --id MyGenome --name "My Organism"

Notes:
  - Staging happens on local disk (mktemp under \$TMPDIR or /tmp), even if
    inputs/output live on a network share (e.g. WSL /mnt/*), to avoid a known
    9p/CIFS bug where zip writes a stale file size into the archive header.
  - The archive is verified after creation (zip integrity + declared vs
    actual entry sizes) before being placed at OUTPUT.
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
keep_tmp=0

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
	--keep-tmp)
		keep_tmp=1
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

require_cmd zip
require_cmd unzip
require_cmd python3
[[ -n "${fai}" ]] || require_cmd samtools

output_base="$(basename "${output}")"
[[ -n "${genome_id}" ]] || genome_id="${output_base%.genome}"
[[ -n "${genome_name}" ]] || genome_name="${genome_id}"

tmpdir="$(mktemp -d "${TMPDIR:-/tmp}/igv_genome.XXXXXX")"
cleanup() {
	if [[ "${keep_tmp}" -eq 1 ]]; then
		echo "staging directory kept at: ${tmpdir}" >&2
	else
		rm -rf "${tmpdir}"
	fi
}
trap cleanup EXIT

fasta_base="$(basename "${fasta}")"
genefile_base="$(basename "${genefile}")"

# Stage inputs on local disk: reading source files from a network mount while
# zip writes can produce a corrupt archive (stale size in the local header).
cp --update=none "${fasta}" "${tmpdir}/${fasta_base}"
cp --update=none "${genefile}" "${tmpdir}/${genefile_base}"

fai_base="${fasta_base}.fai"
if [[ -n "${fai}" ]]; then
	cp --update=none "${fai}" "${tmpdir}/${fai_base}"
else
	(cd "${tmpdir}" && samtools faidx "${fasta_base}")
fi

cat >"${tmpdir}/property.txt" <<EOF
fasta=true
fastaDirectory=false
ordered=true
id=${genome_id}
name=${genome_name}
geneFile=${genefile_base}
sequenceLocation=${fasta_base}
EOF

archive="${tmpdir}/${output_base}"
(cd "${tmpdir}" && zip -j -q "${archive}" property.txt "${fasta_base}" "${fai_base}" "${genefile_base}")

unzip -t "${archive}" >/dev/null || die "zip integrity check failed on staged archive"

python3 - "${archive}" <<'PYEOF'
import sys, zipfile
path = sys.argv[1]
z = zipfile.ZipFile(path)
for info in z.infolist():
    actual = len(z.read(info.filename))
    if actual != info.file_size:
        sys.exit(f"size mismatch in {info.filename}: header says {info.file_size}, actual {actual}")
PYEOF

# Place the verified archive at the requested output. Written in-place via
# Python (not mv/rename) since some network mounts deny renaming over an
# existing/locked file while still allowing a normal write.
python3 -c "
import shutil
shutil.copyfile('${archive}', '${output}')
"

echo "wrote: ${output}"

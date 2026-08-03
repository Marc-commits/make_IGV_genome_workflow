#!/usr/bin/env bats
#
# Run with: bats tests/make_igv_genome.bats

setup() {
	TEST_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
	SCRIPT="${TEST_DIR}/../workflow/scripts/make_igv_genome.sh"
	INPUT_DIR="${TEST_DIR}/input"
	OUTPUT_DIR="${TEST_DIR}/output"
	mkdir -p "${OUTPUT_DIR}"
	FASTA="${INPUT_DIR}/mini.fasta"
	GENEFILE="${INPUT_DIR}/mini.gff"
	OUTPUT="${OUTPUT_DIR}/mini.json"
}

teardown() {
	rm -f "${OUTPUT_DIR}"/*.json "${INPUT_DIR}"/*.fai
}

@test "--help prints usage and exits 0" {
	run "${SCRIPT}" --help
	[ "$status" -eq 0 ]
	[[ "$output" == *"Usage:"* ]]
}

@test "--version prints a version and exits 0" {
	run "${SCRIPT}" --version
	[ "$status" -eq 0 ]
	[[ "$output" == *"make_igv_genome.sh v"* ]]
}

@test "missing required arguments fails with a clear error" {
	run "${SCRIPT}" -f "${FASTA}"
	[ "$status" -ne 0 ]
	[[ "$output" == *"-g/--genefile is required"* ]]
}

@test "nonexistent fasta fails with a clear error" {
	run "${SCRIPT}" -f "${INPUT_DIR}/does_not_exist.fasta" -g "${GENEFILE}" -o "${OUTPUT}"
	[ "$status" -ne 0 ]
	[[ "$output" == *"fasta file not found"* ]]
}

@test "builds a valid JSON genome descriptor from fasta + gff" {
	run "${SCRIPT}" -f "${FASTA}" -g "${GENEFILE}" -o "${OUTPUT}" --id MiniGenome --name "Mini Genome"
	[ "$status" -eq 0 ]
	[ -f "${OUTPUT}" ]
	[ -f "${FASTA}.fai" ]

	run python3 -c "
import json
d = json.load(open('${OUTPUT}'))
assert d['id'] == 'MiniGenome', d
assert d['name'] == 'Mini Genome', d
assert d['fastaURL'] == '../input/mini.fasta', d
assert d['indexURL'] == '../input/mini.fasta.fai', d
assert d['tracks'][0]['name'] == 'Genes', d
assert d['tracks'][0]['url'] == '../input/mini.gff', d
assert d['tracks'][0]['format'] == 'gff', d
assert d['tracks'][0]['indexed'] is False, d
print('ok')
"
	[ "$status" -eq 0 ]
	[[ "$output" == *"ok"* ]]
}

@test "output is syntactically valid JSON" {
	"${SCRIPT}" -f "${FASTA}" -g "${GENEFILE}" -o "${OUTPUT}"
	run python3 -c "import json; json.load(open('${OUTPUT}'))"
	[ "$status" -eq 0 ]
}

@test "does not copy fasta/genefile bytes next to the output" {
	run "${SCRIPT}" -f "${FASTA}" -g "${GENEFILE}" -o "${OUTPUT}"
	[ "$status" -eq 0 ]
	[ ! -f "${OUTPUT_DIR}/mini.fasta" ]
	[ ! -f "${OUTPUT_DIR}/mini.gff" ]
}

@test "refuses to overwrite an existing output without --force" {
	"${SCRIPT}" -f "${FASTA}" -g "${GENEFILE}" -o "${OUTPUT}"
	run "${SCRIPT}" -f "${FASTA}" -g "${GENEFILE}" -o "${OUTPUT}"
	[ "$status" -ne 0 ]
	[[ "$output" == *"already exists"* ]]
}

@test "--force overwrites an existing output" {
	"${SCRIPT}" -f "${FASTA}" -g "${GENEFILE}" -o "${OUTPUT}"
	run "${SCRIPT}" -f "${FASTA}" -g "${GENEFILE}" -o "${OUTPUT}" --force
	[ "$status" -eq 0 ]
}

@test "--fai reuses a pre-existing index instead of regenerating it" {
	samtools faidx "${FASTA}"
	ORIGINAL_MTIME="$(stat -c %Y "${FASTA}.fai")"
	sleep 1
	run "${SCRIPT}" -f "${FASTA}" -g "${GENEFILE}" -o "${OUTPUT}" --fai "${FASTA}.fai"
	[ "$status" -eq 0 ]

	NEW_MTIME="$(stat -c %Y "${FASTA}.fai")"
	[ "${ORIGINAL_MTIME}" -eq "${NEW_MTIME}" ]

	run python3 -c "
import json, os
d = json.load(open('${OUTPUT}'))
resolved = os.path.normpath(os.path.join(os.path.dirname('${OUTPUT}'), d['indexURL']))
assert os.path.samefile(resolved, '${FASTA}.fai'), (resolved, '${FASTA}.fai')
print('ok')
"
	[ "$status" -eq 0 ]
	[[ "$output" == *"ok"* ]]
}

@test "default id/name derive from the output filename" {
	run "${SCRIPT}" -f "${FASTA}" -g "${GENEFILE}" -o "${OUTPUT}"
	[ "$status" -eq 0 ]

	run python3 -c "
import json
d = json.load(open('${OUTPUT}'))
assert d['id'] == 'mini', d
assert d['name'] == 'mini', d
print('ok')
"
	[ "$status" -eq 0 ]
	[[ "$output" == *"ok"* ]]
}

#!/usr/bin/env bats
#
# Run with: bats tests/make_igv_genome.bats
#
# Ported unchanged from bash_scripts/make_IGV_genome/test/make_igv_genome.bats
# (commit 8c2a815) against the vendored copy of the script in this repo.

setup() {
	TEST_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
	SCRIPT="${TEST_DIR}/../workflow/scripts/make_igv_genome.sh"
	INPUT_DIR="${TEST_DIR}/input"
	OUTPUT_DIR="${TEST_DIR}/output"
	mkdir -p "${OUTPUT_DIR}"
	FASTA="${INPUT_DIR}/mini.fasta"
	GENEFILE="${INPUT_DIR}/mini.gff"
	OUTPUT="${OUTPUT_DIR}/mini.genome"
}

teardown() {
	rm -f "${OUTPUT_DIR}"/*.genome "${INPUT_DIR}"/*.fai
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

@test "builds a valid .genome archive from fasta + gff" {
	run "${SCRIPT}" -f "${FASTA}" -g "${GENEFILE}" -o "${OUTPUT}" --id MiniGenome --name "Mini Genome"
	[ "$status" -eq 0 ]
	[ -f "${OUTPUT}" ]

	run unzip -l "${OUTPUT}"
	[ "$status" -eq 0 ]
	[[ "$output" == *"property.txt"* ]]
	[[ "$output" == *"mini.fasta"* ]]
	[[ "$output" == *"mini.fasta.fai"* ]]
	[[ "$output" == *"mini.gff"* ]]

	run unzip -p "${OUTPUT}" property.txt
	[ "$status" -eq 0 ]
	[[ "$output" == *"id=MiniGenome"* ]]
	[[ "$output" == *"name=Mini Genome"* ]]
	[[ "$output" == *"geneFile=mini.gff"* ]]
	[[ "$output" == *"sequenceLocation=mini.fasta"* ]]
}

@test "archive passes zip integrity check" {
	"${SCRIPT}" -f "${FASTA}" -g "${GENEFILE}" -o "${OUTPUT}"
	run unzip -t "${OUTPUT}"
	[ "$status" -eq 0 ]
	[[ "$output" == *"No errors detected"* ]]
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
	run "${SCRIPT}" -f "${FASTA}" -g "${GENEFILE}" -o "${OUTPUT}" --fai "${FASTA}.fai"
	[ "$status" -eq 0 ]

	run unzip -p "${OUTPUT}" mini.fasta.fai
	[ "$status" -eq 0 ]
	diff <(echo "$output") "${FASTA}.fai"
}

@test "default id/name derive from the output filename" {
	run "${SCRIPT}" -f "${FASTA}" -g "${GENEFILE}" -o "${OUTPUT}"
	[ "$status" -eq 0 ]

	run unzip -p "${OUTPUT}" property.txt
	[[ "$output" == *"id=mini"* ]]
	[[ "$output" == *"name=mini"* ]]
}

rule make_igv_genome:
    input:
        fasta=config["fasta"],
        genefile=config["genefile"],
    output:
        genome=config["output"],
    params:
        genome_id=config["genome_id"],
        genome_name=config["genome_name"],
        # Resolved relative to this .smk file (not workflow.basedir, which
        # would resolve to the *consumer's* top-level Snakefile once this
        # module is pulled in via `module:` -- see the snakemake-module
        # skill's workflow.basedir pitfall).
        script=workflow.source_path("../scripts/make_igv_genome.sh"),
    log:
        "logs/make_igv_genome/make_igv_genome.log",
    benchmark:
        "benchmarks/make_igv_genome/make_igv_genome.txt"
    conda:
        "../envs/igv_genome.yaml"
    shell:
        # invoked via `bash` rather than executed directly: workflow.source_path
        # copies the script into Snakemake's source cache without preserving
        # the executable bit
        "bash {params.script} -f {input.fasta} -g {input.genefile} -o {output.genome} "
        "--id {params.genome_id:q} --name {params.genome_name:q} --force &> {log}"

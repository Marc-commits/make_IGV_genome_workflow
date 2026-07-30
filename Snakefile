configfile: "config/config.yaml"


include: "workflow/rules/igv_genome.smk"


rule make_igv_genome_workflow_all:
    """Convenience aggregate target for standalone runs/tests of this module."""
    input:
        config["output"],
    default_target: True

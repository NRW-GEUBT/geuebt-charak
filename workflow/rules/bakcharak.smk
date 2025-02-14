# use bakcharak to get all relevant data


import os


rule get_settings:
    output:
        settings="staging/settings.json",
    params:
        url=config["API_url"],
        organism=config["species"],
    message:
        "[BakCharak] Getting analysis settings"
    conda:
        "../envs/pandas.yaml"
    log:
        "logs/get_settings.log",
    script:
        "../scripts/get_settings.py"


checkpoint bakcharak:
    input:
        settings="staging/settings.json"
    output:
        outdir=directory("bakcharak"),
        # summaries="bakcharak/results/summary/summary_all.tsv",
    params:
        samples=config["sample_sheet"],
        species=lambda w, input: get_setting_value(input.settings, "bakcharak_species"),
        max_threads_per_job=config["max_threads_per_job"],
    message:
        "[BakCharak] Characterizing isolates"
    threads: workflow.cores
    conda:
        "../envs/bakcharak.yaml"
    log:
        "logs/bakcharak.log",
    shell:
        """
        exec 2> {log}
        
        python $CONDA_PREFIX/bakCharak/bakcharak.py \
            --sample_list {params.samples} \
            --working_directory {output.outdir} \
            --species {params.species} \
            --threads {threads} \
            # --threads_sample {params.max_threads_per_job} 
            # --mash_genome_db $HOME/.nrw-geuebt/bakCharak/databases/mash/refseq.genomes.k21s1000.msh \
            # --mash_genome_info $HOME/.nrw-geuebt/bakCharak/databases/mash/refseq.genomes.k21s1000.info \
            # --mash_plasmid_db $HOME/.nrw-geuebt/bakCharak/databases/mash/refseq.plasmid.k21s1000.msh
        """


rule stage_results:
    input:
        summary=aggregate_summaries,
    output:
        sheet_out=directory("staging/charak_sheets"),
        merged="staging/merged_sheets.json",
        qc_out="staging/qc_status.json",
    params:
        API_url=config["API_url"],
        ver=version,
    message:
        "[BakCharak] Staging results"
    conda:
        "../envs/pandas.yaml"
    log:
        "logs/stage_results.log",
    script:
        "../scripts/stage_results.py"

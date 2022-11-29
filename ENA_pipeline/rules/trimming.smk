# bbduk rules adapted from https://snakemake-wrappers.readthedocs.io/en/stable/wrappers/bbtools/bbduk.html

# FOR SINGLE-END DATA
rule fastqc_raw_se:
    input: 
        R="{projid}/raw/{id}.fastq.gz"
    output:
        htmlOut="{projid}/QC/{id}_fastqc_pre/{id}_fastqc.html",
        ziplOut="{projid}/QC/{id}_fastqc_pre/{id}_fastqc.zip"
    params:
        outdir="{projid}/QC/{id}_fastqc_pre",
        contaminants="adapters.txt"
    shell:"""
    mkdir {params.outdir} &&
    fastqc --outdir {params.outdir} --noextract --threads 2 --quiet --contaminants {params.contaminants} {input.R}
    """

# rule trim_bbduk_se:
#     input: 
#         R="{projid}/raw/{id}.fastq.gz"
#     output:
#         trimmed="{projid}/Trimmed/{id}.trim.fq.gz",
#         singleton="{projid}/Trimmed/{id}.single.fq.gz",
#         discarded="{projid}/Trimmed/{id}.discarded.fq.gz",
#         stats="{projid}/Trimmed/{id}.trimk_stats.txt"
#     params:
#         timeFile="{projid}/Trimmed/{id}.trim.time",
#         qin="auto",
#         k="19",
#         adapters="/home/projects/cge/apps/foodqcpipeline/db/adapters.fa",
#         mink="11",
#         qtrim="r",
#         trimq"20",
#         minlength="50"
#     log: "{projid}/Trimmed/{id}.trimq_stats.txt"
#     shell:
#     """
#     /usr/bin/time -v -o {params.timeFile} bbduk.sh qin={params.qin} \
#     k={params.k} rref={params.adapters} mink={params.mink} \
#     qtrim={params.qtrim} trimq={params.trimq} minlength={parmas.minlength} \
#     tbo ziplevel=6 overwrite=t in={input.R} out={output.trimmed} \
#     outs={output.singleton} outm={output.discarded} \
#     statscolumns=5 stats={output.stats} -Xmx7g &> {log}
#     """
# rule fastqc_trim_se:
#     input: 
#         trimmed="{projid}/Trimmed/{id}.trim.fq.gz"
#     output:
#         htmlOut="{projid}/QC/{id}_fastqc_post/{id}.trim_fastqc.html",
#         ziplOut="{projid}/QC/{id}_fastqc_post/{id}.trim_fastqc.zip"
#     params:
#         outdir="{projid}/QC/{id}_fastqc_post"
#         contaminants="/home/projects/cge/apps/foodqcpipeline/db/adapters.txt"
#     shell:
#     """
#     fastqc --outdir {params.outdir} --noextract --threads 2 --quiet --contaminants {params.contaminants} {input.trimmed}
#     """

# # FOR PAIRED-END DATA
# rule fastqc_raw_pe:
#     input: 
#         R1="{projid}/raw/{id}_1.fastq.gz"
#         R2="{projid}/raw/{id}_2.fastq.gz"
#     output:
#         htmlOut="{projid}/QC/{id}_fastqc_pre/{id}_fastqc.html",
#         ziplOut="{projid}/QC/{id}_fastqc_pre/{id}_fastqc.zip"
#     params:
#         outdir="{projid}/QC/{id}_fastqc_pre"
#         contaminants="/home/projects/cge/apps/foodqcpipeline/db/adapters.txt"
#     shell:
#     """
#     fastqc --outdir {params.outdir} --noextract --threads 2 --quiet --contaminants {params.contaminants} {input.R1} {input.R2}
#     """

# rule trim_bbduk_pe:
#     input: 
#         R1="{projid}/raw/{id}_1.fastq.gz"
#         R2="{projid}/raw/{id}_2.fastq.gz"
#     output:
#         R1="{projid}/Trimmed/{id}_1.trim.fq.gz",
#         R2="{projid}/Trimmed/{id}_2.trim.fq.gz",
#         singleton="{projid}/Trimmed/{id}.singletons.fq.gz",
#         discarded="{projid}/Trimmed/{id}.discarded.fq.gz",
#         stats="{projid}/Trimmed/{id}.trimk_stats.txt"
#     params:
#         timeFile="{projid}/Trimmed/{id}.trim.time",
#         qin="auto",
#         k="19",
#         adapters="/home/projects/cge/apps/foodqcpipeline/db/adapters.fa",
#         mink="11",
#         qtrim="r",
#         trimq"20",
#         minlength="50"
#     log: "{projid}/Trimmed/{id}.trimq_stats.txt"    
#     shell: 
#     """
#     /usr/bin/time -v -o {params.timeFile} bbduk.sh qin={params.qin} \
#     k={params.k} rref={params.adapters} mink={params.mink} \
#     qtrim={params.qtrim} trimq={params.trimq} minlength={parmas.minlength} \
#     tbo ziplevel=6 overwrite=t in={input.R} out={output.R1} \
#     in2={input.R2} out2={output.R2}
#     outs={output.singleton} outm={output.discarded} \
#     statscolumns=5 stats={output.stats} -Xmx7g &> {log}
#     """

# rule fastqc_trim_se:
#     input: 
#         R1="{projid}/Trimmed/{id}_1.trim.fq.gz",
#         R2="{projid}/Trimmed/{id}_2.trim.fq.gz",
#     output:
#         htmlOut="{projid}/QC/{id}_fastqc_post/{id}.trim_fastqc.html",
#         ziplOut="{projid}/QC/{id}_fastqc_post/{id}.trim_fastqc.zip"
#     params:
#         outdir="{projid}/QC/{id}_fastqc_post"
#         contaminants="/home/projects/cge/apps/foodqcpipeline/db/adapters.txt"
#     shell:
#     """
#     fastqc --outdir {params.outdir} --noextract --threads 2 --quiet --contaminants {params.contaminants} {input.R1} {input.R2}
#     """

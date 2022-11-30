
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
rule fastqc_trim_se:
    input: 
        trimmed="{projid}/Trimmed/{id}.trim.fq.gz"
    output:
        htmlOut="{projid}/QC/{id}_fastqc_post/{id}.trim_fastqc.html",
        ziplOut="{projid}/QC/{id}_fastqc_post/{id}.trim_fastqc.zip"
    params:
        outdir="{projid}/QC/{id}_fastqc_post"
        contaminants="/home/projects/cge/apps/foodqcpipeline/db/adapters.txt"
    shell:
    """
    fastqc --outdir {params.outdir} --noextract --threads 2 --quiet --contaminants {params.contaminants} {input.trimmed}
    """
rule fastqc_raw_pe:
    input: 
        R1="{projid}/raw/{id}_1.fastq.gz"
        R2="{projid}/raw/{id}_2.fastq.gz"
    output:
        htmlOut="{projid}/QC/{id}_fastqc_pre/{id}_fastqc.html",
        ziplOut="{projid}/QC/{id}_fastqc_pre/{id}_fastqc.zip"
    params:
        outdir="{projid}/QC/{id}_fastqc_pre"
        contaminants="/home/projects/cge/apps/foodqcpipeline/db/adapters.txt"
    shell:
    """
    fastqc --outdir {params.outdir} --noextract --threads 2 --quiet --contaminants {params.contaminants} {input.R1} {input.R2}
    """

rule fastqc_trim_se:
    input: 
        R1="{projid}/Trimmed/{id}_1.trim.fq.gz",
        R2="{projid}/Trimmed/{id}_2.trim.fq.gz",
    output:
        htmlOut="{projid}/QC/{id}_fastqc_post/{id}.trim_fastqc.html",
        ziplOut="{projid}/QC/{id}_fastqc_post/{id}.trim_fastqc.zip"
    params:
        outdir="{projid}/QC/{id}_fastqc_post"
        contaminants="/home/projects/cge/apps/foodqcpipeline/db/adapters.txt"
    shell:
    """
    fastqc --outdir {params.outdir} --noextract --threads 2 --quiet --contaminants {params.contaminants} {input.R1} {input.R2}
    """

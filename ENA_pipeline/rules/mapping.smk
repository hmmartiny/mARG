rule kma_resfinder:
    input:
        R1="{projid}/Trimmed/{id}_R1.trim.fq.gz",
        R2="{projid}/Trimmed/{id}_R2.trim.fq.gz",
        S="{projid}/Trimmed/{id}_R1.singletons.fq.gz"
    output:
        mapstat="{projid}/kma/ResFinder/{id}.mapstat"
    params:
        mapstat="{projid}/kma/ResFinder/{id}"
    threads: 20
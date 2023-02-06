import json
import os

include: "rules/analysis_paired_read.smk"
include: "rules/analysis_single_read.smk"

with open("input_samples.json", 'r') as f:
  data = json.load(f)

accession=[]
accession_type=[]

for sample_id in data:
	accession.append(sample_id)
for sample_id_type in data.values():
	accession_type.append(sample_id_type["type"])

merge=zip(accession,accession_type)
new_merge=dict(merge)

single=[]
paired=[]

for k,v in new_merge.items():
	if ("SINGLE") in v:
		single.append(k)
	elif ("PAIRED") in v:
		paired.append(k)

rule all:
	input:
		expand("results/raw_reads/paired_end/{paired_reads}/{paired_reads}_1.fastq.gz", paired_reads=paired),
		expand("results/raw_reads/paired_end/{paired_reads}/{paired_reads}_2.fastq.gz", paired_reads=paired),
		expand("results/raw_reads/single_end/{single_reads}/{single_reads}.fastq.gz", single_reads=single),
		expand("results/fastqc/paired_end/{paired_reads}/{paired_reads}_1_fastqc.html", paired_reads=paired),
		expand("results/fastqc/paired_end/{paired_reads}/{paired_reads}_2_fastqc.html", paired_reads=paired),
		expand("results/fastqc/single_end/{single_reads}/{single_reads}_fastqc.html", single_reads=single),
		expand("results/trimmed_reads/paired_end/{paired_reads}/{paired_reads}_1.trimmed.fastq.gz", paired_reads=paired),
		expand("results/trimmed_reads/paired_end/{paired_reads}/{paired_reads}_2.trimmed.fastq.gz", paired_reads=paired),
		expand("results/trimmed_reads/single_end/{single_reads}/{single_reads}.trimmed.fastq.gz", single_reads=single),
		expand("results/fastqc_recheck/paired_end/{paired_reads}/{paired_reads}_1.trimmed_fastqc.html", paired_reads=paired),
		expand("results/fastqc_recheck/paired_end/{paired_reads}/{paired_reads}_2.trimmed_fastqc.html", paired_reads=paired),
		expand("results/fastqc_recheck/single_end/{single_reads}/{single_reads}.trimmed_fastqc.html", single_reads=single),
		expand("results/spades/paired_end/{paired_reads}/{paired_reads}.scaffolds.fasta", paired_reads=paired),
		expand("results/spades/single_end/{single_reads}/{single_reads}.scaffolds.fasta", single_reads=single),
		#expand("results/kma_resfinder/paired_end/{paired_reads}/{paired_reads}.res", paired_reads=paired),
		#expand("results/kma_resfinder/paired_end/{paired_reads}/{paired_reads}.vcf.gz", paired_reads=paired),
		#expand("results/kma_resfinder/paired_end/{paired_reads}/{paired_reads}.mapstat", paired_reads=paired),
		#expand("results/kma_resfinder/paired_end/{paired_reads}/{paired_reads}.sam", paired_reads=paired),
		#expand("results/kma_resfinder/single_end/{single_reads}/{single_reads}.res", single_reads=single),
		#expand("results/kma_resfinder/single_end/{single_reads}/{single_reads}.vcf.gz", single_reads=single),
		#expand("results/kma_resfinder/single_end/{single_reads}/{single_reads}.mapstat", single_reads=single),
		#expand("results/kma_resfinder/single_end/{single_reads}/{single_reads}.sam", single_reads=single),
		#expand("results/kma_mOTUs/paired_end/{paired_reads}/{paired_reads}.res", paired_reads=paired),
		#expand("results/kma_mOTUs/paired_end/{paired_reads}/{paired_reads}.mapstat", paired_reads=paired),
		#expand("results/kma_mOTUs/paired_end/{paired_reads}/{paired_reads}.sorted.bam", paired_reads=paired),
		#expand("results/kma_mOTUs/single_end/{single_reads}/{single_reads}.res", single_reads=single),
		#expand("results/kma_mOTUs/single_end/{single_reads}/{single_reads}.mapstat", single_reads=single),
		#expand("results/kma_mOTUs/single_end/{single_reads}/{single_reads}.sorted.bam", single_reads=single),
		#expand("results/kma_silva/paired_end/{paired_reads}/{paired_reads}.res", paired_reads=paired),
		#expand("results/kma_silva/paired_end/{paired_reads}/{paired_reads}.mapstat", paired_reads=paired),
		#expand("results/kma_silva/paired_end/{paired_reads}/{paired_reads}.sorted.bam", paired_reads=paired),
		#expand("results/kma_silva/single_end/{single_reads}/{single_reads}.res", single_reads=single),
		#expand("results/kma_silva/single_end/{single_reads}/{single_reads}.mapstat", single_reads=single),
		#expand("results/kma_silva/single_end/{single_reads}/{single_reads}.sorted.bam", single_reads=single),
		#expand("results/kma_gigaRes/paired_end/{paired_reads}/{paired_reads}.res", paired_reads=paired),
		#expand("results/kma_gigaRes/paired_end/{paired_reads}/{paired_reads}.vcf.gz", paired_reads=paired),
		#expand("results/kma_gigaRes/paired_end/{paired_reads}/{paired_reads}.mapstat", paired_reads=paired),
		#expand("results/kma_gigaRes/paired_end/{paired_reads}/{paired_reads}.sorted.bam", paired_reads=paired),
		#expand("results/kma_gigaRes/single_end/{single_reads}/{single_reads}.res", single_reads=single),
		#expand("results/kma_gigaRes/single_end/{single_reads}/{single_reads}.vcf.gz", single_reads=single),
		#expand("results/kma_gigaRes/single_end/{single_reads}/{single_reads}.mapstat", single_reads=single),
		#expand("results/kma_gigaRes/single_end/{single_reads}/{single_reads}.sorted.bam", single_reads=single),
		#expand("results/kma_genomic/paired_end/{paired_reads}/{paired_reads}.res", paired_reads=paired),
		#expand("results/kma_genomic/paired_end/{paired_reads}/{paired_reads}.mapstat", paired_reads=paired),
		#expand("results/kma_genomic/paired_end/{paired_reads}/{paired_reads}.sorted.bam", paired_reads=paired),
		#expand("results/kma_genomic/single_end/{single_reads}/{single_reads}.res", single_reads=single),
		#expand("results/kma_genomic/single_end/{single_reads}/{single_reads}.mapstat", single_reads=single),
		#expand("results/kma_genomic/single_end/{single_reads}/{single_reads}.sorted.bam", single_reads=single),
		#expand("results/samtools/paired_end/{paired_reads}/{paired_reads}.sorted.bam", paired_reads=paired),
		#expand("results/samtools/single_end/{single_reads}/{single_reads}.sorted.bam", single_reads=single),
		expand("results/mash_sketch/paired_end/{paired_reads}/{paired_reads}.trimmed.fastq.gz.msh", paired_reads=paired),
		expand("results/mash_sketch/single_end/{single_reads}/{single_reads}.trimmed.fastq.gz.msh", single_reads=single),
		expand("results/seed_extender/paired_end/{paired_reads}/{paired_reads}.fasta", paired_reads=paired),
		expand("results/seed_extender/single_end/{single_reads}/{single_reads}.fasta", single_reads=single)
		
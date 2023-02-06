rule download_single_end_reads:
	"""
	Downloading metagenomic raw single end reads from ENA using enaDataGet
	"""
	output:
		"results/raw_reads/single_end/{single_reads}/{single_reads}.fastq.gz"
	params:
		outdir="results/raw_reads/single_end",
		type="fastq"
	envmodules:
		"tools",
		"anaconda3/2022.10",
		"enabrowsertools/1.1.0"
	shell:
		"""
		/usr/bin/time -v --output=results/raw_reads/single_end/{wildcards.single_reads}/{wildcards.single_reads}.bench enaDataGet -f {params.type} -d {params.outdir} {wildcards.single_reads}
		""" 

rule quality_check_single_end_reads:
	"""
	Quality check of raw single end reads using FASTQC
	"""
	input:
		"results/raw_reads/single_end/{single_reads}/{single_reads}.fastq.gz"
	output:
		"results/fastqc/single_end/{single_reads}/{single_reads}_fastqc.html"
	params:
		outdir="results/fastqc/single_end/{single_reads}"
	envmodules:
		"tools",
		"perl/5.30.2",
		"jdk/19",
		"fastqc/0.11.9"
	shell:
		"""
    	/usr/bin/time -v --output=results/fastqc/single_end/{wildcards.single_reads}/{wildcards.single_reads}.bench fastqc {input} -o {params.outdir}
		"""

rule trim_single_end_reads:
	"""
	Adapter trimming of raw single end reads using BBDuk
	"""
	input:
		"results/raw_reads/single_end/{single_reads}/{single_reads}.fastq.gz"
	output:
		"results/trimmed_reads/single_end/{single_reads}/{single_reads}.trimmed.fastq.gz"
	params:
		qin="auto",
		k="19",
		ref="adapters",
		mink="11",
		qtrim="r",
		trimq="20",
		minlength="50",
		ziplevel="6",
		overwrite="t",
		statscolumns="5",
		ktrim="r"
	envmodules:
		"tools",
		"jdk/19",
		"bbmap/38.90"
	shell:
		"""
		/usr/bin/time -v --output=results/trimmed_reads/single_end/{wildcards.single_reads}/{wildcards.single_reads}.bench bbduk.sh in={input} out={output} qin={params.qin} ref={params.ref} k={params.k} qtrim={params.qtrim} mink={params.mink} trimq={params.trimq} minlength={params.minlength} ziplevel={params.ziplevel} overwrite={params.overwrite} statscolumns={params.statscolumns} ktrim={params.ktrim} tbo
		"""

rule quality_recheck_single_end_reads:
	"""
	Quality check of raw single end reads using FASTQC
	"""
	input:
		"results/trimmed_reads/single_end/{single_reads}/{single_reads}.trimmed.fastq.gz"
	output:
		"results/fastqc_recheck/single_end/{single_reads}/{single_reads}.trimmed_fastqc.html"
	params:
		outdir="results/fastqc_recheck/single_end/{single_reads}"
	envmodules:
		"tools",
		"perl/5.30.2",
		"jdk/19",
		"fastqc/0.11.9"
	shell:
		"""
    	/usr/bin/time -v --output=results/fastqc_recheck/single_end/{wildcards.single_reads}/{wildcards.single_reads}.bench fastqc {input} -o {params.outdir}
		"""

rule metaspades_single_end_reads:
	"""
	De novo assembly of the single end reads using spades
	"""
	input:
		"results/trimmed_reads/single_end/{single_reads}/{single_reads}.trimmed.fastq.gz"
	output:
		"results/spades/single_end/{single_reads}/{single_reads}.scaffolds.fasta"
	params:
		fastq="results/trimmed_reads/single_end/{single_reads}/{single_reads}.trimmed.fastq.gz",
		outdir = "results/spades/single_end/{single_reads}",
		old_scaffolds = "results/spades/single_end/{single_reads}/scaffolds.fasta",
		new_scaffolds = "results/spades/single_end/{single_reads}/{single_reads}.scaffolds.fasta"
	envmodules:
		"tools",
		"anaconda3/2022.10",
		"spades/3.15.5"
	shell:
		"""
		/usr/bin/time -v --output=results/spades/single_end/{wildcards.single_reads}/{wildcards.single_reads}.bench spades.py -s {params.fastq} -o {params.outdir} -k 27,47,67,87,107,127
		mv {params.old_scaffolds} {params.new_scaffolds}  
		"""

rule kma_single_end_reads_resfinder:
    	"""
    	Mapping raw single reads for identifying AMR using KMA
    	"""
    	input: 
         	"results/trimmed_reads/single_end/{single_reads}/{single_reads}.trimmed.fastq.gz"
    	output:
        	"results/kma_resfinder/single_end/{single_reads}/{single_reads}.res",
        	"results/kma_resfinder/single_end/{single_reads}/{single_reads}.vcf.gz",
        	"results/kma_resfinder/single_end/{single_reads}/{single_reads}.mapstat",
        	"results/kma_resfinder/single_end/{single_reads}/{single_reads}.sam"
	params:
		db="/home/databases/metagenomics/db/ResFinder_20220825/ResFinder_20220825",
		outdir="results/kma_resfinder/single_end/{single_reads}/{single_reads}",
		kma_params="-mem_mode -ef -1t1 -nf -vcf -sam -matrix"
	envmodules:
		"tools",
		"kma/1.4.7"
	shell:
		"""
		/usr/bin/time -v --output=results/kma_resfinder/single_end/{wildcards.single_reads}/{wildcards.single_reads}.bench kma -i {input} -o {params.outdir} -t_db {params.db} {params.kma_params} > results/kma_resfinder/single_end/{wildcards.single_reads}/{wildcards.single_reads}.sam
		"""   

rule kma_single_end_reads_mOTUs:
    	"""
    	Mapping raw single reads for identifying AMR using KMA with mOTUs db
    	"""
    	input: 
         	"results/trimmed_reads/single_end/{single_reads}/{single_reads}.trimmed.fastq.gz"
    	output:
        	"results/kma_mOTUs/single_end/{single_reads}/{single_reads}.res",
        	"results/kma_mOTUs/single_end/{single_reads}/{single_reads}.mapstat",
        	"results/kma_mOTUs/single_end/{single_reads}/{single_reads}.sorted.bam"
	params:
		db="/home/databases/metagenomics/db/mOTUs_20221205/db_mOTU_20221205",
		outdir="results/kma_mOTUs/single_end/{single_reads}/{single_reads}",
		kma_params="-mem_mode -ef -1t1 -apm f -nf -sam -matrix",
		reference="/home/databases/metagenomics/db/mOTUs_20221205/db_mOTU/db_mOTU_DB_CEN.fasta"
	envmodules:
		"tools",
		"kma/1.4.7",
		"samtools/1.16"
	shell:
		"""
		/usr/bin/time -v --output=results/kma_mOTUs/single_end/{wildcards.single_reads}/{wildcards.single_reads}.bench kma -i {input} -o {params.outdir} -t_db {params.db} {params.kma_params} |samtools fixmate -m - -| samtools view -u -bh -F 4 |samtools sort -o results/kma_mOTUs/single_end/{wildcards.single_reads}/{wildcards.single_reads}.sorted.bam
		"""

rule kma_single_end_reads_Silva:
    	"""
    	Mapping raw single reads for identifying AMR using KMA with Silva db
    	"""
    	input: 
         	"results/trimmed_reads/single_end/{single_reads}/{single_reads}.trimmed.fastq.gz"
    	output:
        	"results/kma_silva/single_end/{single_reads}/{single_reads}.res",
        	"results/kma_silva/single_end/{single_reads}/{single_reads}.mapstat",
        	"results/kma_silva/single_end/{single_reads}/{single_reads}.sorted.bam"
	params:
		db="/home/databases/metagenomics/db/Silva_20200116/Silva_20200116",
		outdir="results/kma_silva/single_end/{single_reads}/{single_reads}",
		kma_params="-mem_mode -ef -1t1 -nf -sam -matrix",
		reference="/home/databases/metagenomics/db/Silva_20200116/SILVA_138_SSURef_tax_silva.fasta.gz"
	envmodules:
		"tools",
		"kma/1.4.7",
		"samtools/1.16"
	shell:
		"""
		/usr/bin/time -v --output=results/kma_silva/single_end/{wildcards.single_reads}/{wildcards.single_reads}.bench kma -i {input} -o {params.outdir} -t_db {params.db} {params.kma_params} |samtools fixmate -m - -| samtools view -u -bh -F 4 |samtools sort -o results/kma_silva/single_end/{wildcards.single_reads}/{wildcards.single_reads}.sorted.bam
		"""

rule kma_single_end_reads_gigaRes:
    	"""
    	Mapping raw single reads for identifying AMR using KMA with gigaRes db
    	"""
    	input: 
         	"results/trimmed_reads/single_end/{single_reads}/{single_reads}.trimmed.fastq.gz"
    	output:
        	"results/kma_gigaRes/single_end/{single_reads}/{single_reads}.res",
        	"results/kma_gigaRes/single_end/{single_reads}/{single_reads}.vcf.gz",
        	"results/kma_gigaRes/single_end/{single_reads}/{single_reads}.mapstat",
        	"results/kma_gigaRes/single_end/{single_reads}/{single_reads}.sorted.bam"
	params:
		db="/home/projects/cge/data/projects/other/niki/snakemake/ava_2.0/prerequisites/gigaRes_db/giga_res20220125",
		outdir="results/kma_gigaRes/single_end/{single_reads}/{single_reads}",
		kma_params="-mem_mode -ef -1t1 -nf -vcf -sam -matrix",
		reference="prerequisites/gigaRes_db/giga_res.uniq.fa"
	envmodules:
		"tools",
		"kma/1.4.7",
		"samtools/1.16"
	shell:
		"""
		/usr/bin/time -v --output=results/kma_gigaRes/single_end/{wildcards.single_reads}/{wildcards.single_reads}.bench kma -i {input} -o {params.outdir} -t_db {params.db} {params.kma_params} |samtools fixmate -m - -| samtools view -u -bh -F 4 --reference {params.reference} |samtools sort -o results/kma_gigaRes/single_end/{wildcards.single_reads}/{wildcards.single_reads}.sorted.bam
		"""  

rule kma_single_end_reads_genomic:
    	"""
    	Mapping raw single reads for identifying AMR using KMA with genomic db
    	"""
    	input: 
         	"results/trimmed_reads/single_end/{single_reads}/{single_reads}.trimmed.fastq.gz"
    	output:
        	"results/kma_genomic/single_end/{single_reads}/{single_reads}.res",
        	"results/kma_genomic/single_end/{single_reads}/{single_reads}.mapstat",
        	"results/kma_genomic/single_end/{single_reads}/{single_reads}.sorted.bam"
	params:
		db="/home/databases/metagenomics/kma_db/genomic_20220524/genomic_20220524",
		outdir="results/kma_genomic/single_end/{single_reads}/{single_reads}",
		kma_params="-mem_mode -ef -1t1 -apm f -nf -sam -matrix"
	envmodules:
		"tools",
		"kma/1.4.7"
	shell:
		"""
		/usr/bin/time -v --output=results/kma_genomic/single_end/{wildcards.single_reads}/{wildcards.single_reads}.bench kma -i {input} -o {params.outdir} -t_db {params.db} {params.kma_params} |samtools fixmate -m - -| samtools view -u -bh -F 4 |samtools sort -o results/kma_genomic/single_end/{wildcards.single_reads}/{wildcards.single_reads}.sorted.bam
		""" 

rule samtools_single_end_reads:
	"""
	Fixing pair coordinates and sorting using Samtools
	"""
	input:
		"results/kma/single_end/{single_reads}/{single_reads}.sam"
	output:
		"results/samtools/single_end/{single_reads}/{single_reads}.sorted.bam"
	envmodules:
		"tools",
		"samtools/1.16"
	shell:
		"""
		/usr/bin/time -v --output=results/samtools/single_end/{wildcards.single_reads}/{wildcards.single_reads}.bench samtools fixmate -m {input} -| samtools view -u -F 4 |samtools sort -o {output}
		"""

rule mash_sketch_single_end_reads:
	"""
	Creation of mash sketches of single end reads using mash
	"""
	input:
		"results/trimmed_reads/single_end/{single_reads}/{single_reads}.trimmed.fastq.gz"
	output:
		"results/mash_sketch/single_end/{single_reads}/{single_reads}.trimmed.fastq.gz.msh"
	envmodules:
		"tools",
		"mash/2.3"
	shell:
		"""
		/usr/bin/time -v --output=results/mash_sketch/single_end/{wildcards.single_reads}/{wildcards.single_reads}.bench mash sketch {input}
		mv results/trimmed_reads/single_end/{wildcards.single_reads}/*.msh results/mash_sketch/single_end/{wildcards.single_reads}
		"""

rule seed_extender_single_reads:
	"""
	Performing local seed extension of paired reads using perl script
	"""
	input:
		"results/trimmed_reads/single_end/{single_reads}/{single_reads}.trimmed.fastq.gz"
	output:
		"results/seed_extender/single_end/{single_reads}/{single_reads}.fasta"
	params:
		seed="-1",
		temp_dir="results/seed_extender/single_end/{single_reads}/{single_reads}",
		db="prerequisites/resfinder_db/resfinder_db_all.fsa"
	envmodules:
		"tools",
		"kma/1.4.7",
		"anaconda3/2022.10",
		"spades/3.15.5",
		"fqgrep/20221222"
	shell:
		"""
		/usr/bin/time -v --output=results/seed_extender/single_end/{wildcards.single_reads}/{wildcards.single_reads}.bench perl prerequisites/seed_extender/targetAsm.pl {params.seed} {params.temp_dir} {params.db} {input}
		"""

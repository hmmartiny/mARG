rule download_paired_end_reads:
	"""
	Downloading metagenomic raw paired end reads from ENA using enaDataGet
	"""
	output:
		"results/raw_reads/paired_end/{paired_reads}/{paired_reads}_1.fastq.gz",
		"results/raw_reads/paired_end/{paired_reads}/{paired_reads}_2.fastq.gz"
	params:
		outdir="results/raw_reads/paired_end",
		type="fastq"
	envmodules:
		"tools",
		"anaconda3/2022.10",
		"enabrowsertools/1.1.0"
	shell:
		"""
		/usr/bin/time -v --output=results/raw_reads/paired_end/{wildcards.paired_reads}/{wildcards.paired_reads}.bench enaDataGet -f {params.type} -d {params.outdir} {wildcards.paired_reads}
		"""

rule quality_check_paired_end_reads:
	"""
	Quality check of raw paired end reads using FASTQC
	"""
	input:
		"results/raw_reads/paired_end/{paired_reads}/{paired_reads}_1.fastq.gz",
		"results/raw_reads/paired_end/{paired_reads}/{paired_reads}_2.fastq.gz"
	output:
		"results/fastqc/paired_end/{paired_reads}/{paired_reads}_1_fastqc.html",
		"results/fastqc/paired_end/{paired_reads}/{paired_reads}_2_fastqc.html"
	params:
		outdir="results/fastqc/paired_end/{paired_reads}"
	envmodules:
		"tools",
		"perl/5.30.2",
		"jdk/19",
		"fastqc/0.11.9"
	shell:
		"""
    	/usr/bin/time -v --output=results/fastqc/paired_end/{wildcards.paired_reads}/{wildcards.paired_reads}.bench fastqc {input} -o {params.outdir}
    	"""

rule trim_paired_end_reads:
	"""
	Adapter trimming of raw paired end reads using BBDuk
	"""
	input:
		in1="results/raw_reads/paired_end/{paired_reads}/{paired_reads}_1.fastq.gz",
		in2="results/raw_reads/paired_end/{paired_reads}/{paired_reads}_2.fastq.gz"
	output:
		out1="results/trimmed_reads/paired_end/{paired_reads}/{paired_reads}_1.trimmed.fastq.gz",
		out2="results/trimmed_reads/paired_end/{paired_reads}/{paired_reads}_2.trimmed.fastq.gz"
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
		/usr/bin/time -v --output=results/trimmed_reads/paired_end/{wildcards.paired_reads}/{wildcards.paired_reads}.bench bbduk.sh in1={input.in1} in2={input.in2} out1={output.out1} out2={output.out2} ref={params.ref} k={params.k} qtrim={params.qtrim} mink={params.mink} trimq={params.trimq} minlength={params.minlength} ziplevel={params.ziplevel} overwrite={params.overwrite} statscolumns={params.statscolumns} ktrim={params.ktrim} tbo
		"""

rule quality_recheck_paired_end_reads:
	"""
	Quality check of raw paired end reads using FASTQC
	"""
	input:
		"results/trimmed_reads/paired_end/{paired_reads}/{paired_reads}_1.trimmed.fastq.gz",
		"results/trimmed_reads/paired_end/{paired_reads}/{paired_reads}_2.trimmed.fastq.gz"
	output:
		"results/fastqc_recheck/paired_end/{paired_reads}/{paired_reads}_1.trimmed_fastqc.html",
		"results/fastqc_recheck/paired_end/{paired_reads}/{paired_reads}_2.trimmed_fastqc.html"
	params:
		outdir="results/fastqc_recheck/paired_end/{paired_reads}"
	envmodules:
		"tools",
		"perl/5.30.2",
		"jdk/19",
		"fastqc/0.11.9"
	shell:
		"""
    	/usr/bin/time -v --output=results/fastqc_recheck/paired_end/{wildcards.paired_reads}/{wildcards.paired_reads}.bench fastqc {input} -o {params.outdir}
    	"""

rule metaspades_paired_end_reads:
	"""
	De novo assembly of the paired end reads using spades
	"""
	input:
		"results/trimmed_reads/paired_end/{paired_reads}/{paired_reads}_1.trimmed.fastq.gz",
		"results/trimmed_reads/paired_end/{paired_reads}/{paired_reads}_2.trimmed.fastq.gz"
	output:
		"results/spades/paired_end/{paired_reads}/{paired_reads}.scaffolds.fasta"
	params:
		fastq1="results/trimmed_reads/paired_end/{paired_reads}/{paired_reads}_1.trimmed.fastq.gz",
		fastq2="results/trimmed_reads/paired_end/{paired_reads}/{paired_reads}_2.trimmed.fastq.gz",
		outdir = "results/spades/paired_end/{paired_reads}",
		old_scaffolds = "results/spades/paired_end/{paired_reads}/scaffolds.fasta",
		new_scaffolds = "results/spades/paired_end/{paired_reads}/{paired_reads}.scaffolds.fasta"
	envmodules:
		"tools",
		"anaconda3/2022.10",
		"spades/3.15.5"
	shell:
		"""
		/usr/bin/time -v --output=results/spades/paired_end/{wildcards.paired_reads}/{wildcards.paired_reads}.bench metaspades.py -1 {params.fastq1} -2 {params.fastq2} -o {params.outdir} -k 27,47,67,87,107,127
		mv {params.old_scaffolds} {params.new_scaffolds}  
		"""

rule kma_paired_end_reads_resfinder:
    	"""
    	Mapping raw paired reads for identifying AMR using KMA with resfinder db
   	"""
    	input: 
        	read_1="results/trimmed_reads/paired_end/{paired_reads}/{paired_reads}_1.trimmed.fastq.gz",
        	read_2="results/trimmed_reads/paired_end/{paired_reads}/{paired_reads}_2.trimmed.fastq.gz"
    	output:
        	"results/kma_resfinder/paired_end/{paired_reads}/{paired_reads}.res",
        	"results/kma_resfinder/paired_end/{paired_reads}/{paired_reads}.vcf.gz",
        	"results/kma_resfinder/paired_end/{paired_reads}/{paired_reads}.mapstat",
        	"results/kma_resfinder/paired_end/{paired_reads}/{paired_reads}.bam"
    	params:
        	db="prerequisites/resfinder_db/resfinder_db_all.fsa",
        	outdir="results/kma_resfinder/paired_end/{paired_reads}/{paired_reads}",
        	kma_params="-mem_mode -ef -1t1 -nf -vcf -sam -matrix"
	envmodules:
		"tools",
		"kma/1.4.7"
	shell:
		"""
		/usr/bin/time -v --output=results/kma_resfinder/paired_end/{wildcards.paired_reads}/{wildcards.paired_reads}.bench kma -ipe {input.read_1} {input.read_2} -o {params.outdir} -t_db {params.db} {params.kma_params} |samtools fixmate -m - -|samtools view -u -bh -F 4|samtools sort -o results/kma_resfinder/paired_end/{wildcards.paired_reads}/{wildcards.paired_reads}.bam
		"""   

rule kma_paired_end_reads_mOTUs:
    	"""
    	Mapping raw paired reads for identifying AMR using KMA with mOTUs db
    	"""
    	input: 
         	read_1="results/trimmed_reads/paired_end/{paired_reads}/{paired_reads}_1.trimmed.fastq.gz",
        	read_2="results/trimmed_reads/paired_end/{paired_reads}/{paired_reads}_2.trimmed.fastq.gz"
    	output:
        	"results/kma_mOTUs/paired_end/{paired_reads}/{paired_reads}.res",
        	"results/kma_mOTUs/paired_end/{paired_reads}/{paired_reads}.mapstat",
        	"results/kma_mOTUs/paired_end/{paired_reads}/{paired_reads}.bam"
	params:
		db="/home/databases/metagenomics/db/mOTUs_20221205/db_mOTU_20221205",
		outdir="results/kma_mOTUs/paired_end/{paired_reads}/{paired_reads}",
		kma_params="-mem_mode -ef -1t1 -apm f -nf -sam -matrix"
	envmodules:
		"tools",
		"kma/1.4.7",
		"samtools/1.16"
	shell:
		"""
		/usr/bin/time -v --output=results/kma_mOTUs/paired_end/{wildcards.paired_reads}/{wildcards.paired_reads}.bench kma -ipe {input.read_1} {input.read_2} -o {params.outdir} -t_db {params.db} {params.kma_params} |samtools fixmate -m - -|samtools view -u -bh -F 4|samtools sort -o results/kma_mOTUs/paired_end/{wildcards.paired_reads}/{wildcards.paired_reads}.bam
		"""  

rule kma_paired_end_reads_Silva:
    	"""
    	Mapping raw paired reads for identifying AMR using KMA with Silva db
    	"""
    	input: 
         	read_1="results/trimmed_reads/paired_end/{paired_reads}/{paired_reads}_1.trimmed.fastq.gz",
        	read_2="results/trimmed_reads/paired_end/{paired_reads}/{paired_reads}_2.trimmed.fastq.gz"
    	output:
        	"results/kma_silva/paired_end/{paired_reads}/{paired_reads}.res",
        	"results/kma_silva/paired_end/{paired_reads}/{paired_reads}.mapstat",
        	"results/kma_silva/paired_end/{paired_reads}/{paired_reads}.bam"
	params:
		db="/home/databases/metagenomics/db/Silva_20200116/Silva_20200116",
		outdir="results/kma_silva/paired_end/{paired_reads}/{paired_reads}",
		kma_params="-mem_mode -ef -1t1 -nf -sam -matrix"
	envmodules:
		"tools",
		"kma/1.4.7",
		"samtools/1.16"
	shell:
		"""
		/usr/bin/time -v --output=results/kma_silva/paired_end/{wildcards.paired_reads}/{wildcards.paired_reads}.bench kma -ipe {input} -o {params.outdir} -t_db {params.db} {params.kma_params} |samtools fixmate -m - -| samtools view -u -bh -F 4 |samtools sort -o results/kma_silva/paired_end/{wildcards.paired_reads}/{wildcards.paired_reads}.sorted.bam
		"""

rule kma_paired_end_reads_gigaRes:
    	"""
    	Mapping raw paired reads for identifying AMR using KMA with gigaRes db
    	"""
    	input: 
         	read_1="results/trimmed_reads/paired_end/{paired_reads}/{paired_reads}_1.trimmed.fastq.gz",
        	read_2="results/trimmed_reads/paired_end/{paired_reads}/{paired_reads}_2.trimmed.fastq.gz"
    	output:
        	"results/kma_gigaRes/paired_end/{paired_reads}/{paired_reads}.res",
        	"results/kma_gigaRes/paired_end/{paired_reads}/{paired_reads}.vcf.gz",
        	"results/kma_gigaRes/paired_end/{paired_reads}/{paired_reads}.mapstat",
        	"results/kma_gigaRes/paired_end/{paired_reads}/{paired_reads}.bam"
	params:
		db="/home/projects/cge/data/projects/other/niki/snakemake/ava_2.0/prerequisites/gigaRes_db/giga_res20220125",
		outdir="results/kma_gigaRes/paired_end/{paired_reads}/{paired_reads}",
		kma_params="-mem_mode -ef -1t1 -nf -vcf -sam -matrix",
		reference="prerequisites/gigaRes_db/giga_res.uniq.fa"
	envmodules:
		"tools",
		"kma/1.4.7",
		"samtools/1.16"
	shell:
		"""
		/usr/bin/time -v --output=results/kma_gigaRes/paired_end/{wildcards.paired_reads}/{wildcards.paired_reads}.bench kma -ipe {input} -o {params.outdir} -t_db {params.db} {params.kma_params} |samtools fixmate -m - -| samtools view -u -bh -F 4 --reference {params.reference} |samtools sort -o results/kma_gigaRes/paired_end/{wildcards.paired_reads}/{wildcards.paired_reads}.bam
		"""  

rule kma_paired_end_reads_genomic:
    	"""
    	Mapping raw paired reads for identifying AMR using KMA with genomic db
    	"""
    	input: 
         	read_1="results/trimmed_reads/paired_end/{paired_reads}/{paired_reads}_1.trimmed.fastq.gz",
        	read_2="results/trimmed_reads/paired_end/{paired_reads}/{paired_reads}_2.trimmed.fastq.gz"
    	output:
        	"results/kma_genomic/paired_end/{paired_reads}/{paired_reads}.res",
        	"results/kma_genomic/paired_end/{paired_reads}/{paired_reads}.mapstat",
        	"results/kma_genomic/paired_end/{paired_reads}/{paired_reads}.bam"
	params:
		db="/home/databases/metagenomics/kma_db/genomic_20220524/genomic_20220524",
		outdir="results/kma_genomic/paired_end/{paired_reads}/{paired_reads}",
		kma_params="-mem_mode -ef -1t1 -apm f -nf -sam -matrix"
	envmodules:
		"tools",
		"kma/1.4.7",
		"samtools/1.16"
	shell:
		"""
		/usr/bin/time -v --output=results/kma_genomic/paired_end/{wildcards.paired_reads}/{wildcards.paired_reads}.bench kma -ipe {input} -o {params.outdir} -t_db {params.db} {params.kma_params} |samtools fixmate -m - -| samtools view -u -bh -F 4 |samtools sort -o results/kma_genomic/paired_end/{wildcards.paired_reads}/{wildcards.paired_reads}.bam
		""" 

rule mash_sketch_paired_end_reads:
	"""
	Creation of mash sketches of paired end reads using mash
	"""
	input:
		read_1="results/trimmed_reads/paired_end/{paired_reads}/{paired_reads}_1.trimmed.fastq.gz",
		read_2="results/trimmed_reads/paired_end/{paired_reads}/{paired_reads}_2.trimmed.fastq.gz"
	output:
		"results/mash_sketch/paired_end/{paired_reads}/{paired_reads}.trimmed.fastq.gz.msh"
	envmodules:
		"tools",
		"mash/2.3"
	shell:
		"""
		/usr/bin/time -v --output=results/mash_sketch/paired_end/{wildcards.paired_reads}/{wildcards.paired_reads}.bench_cat cat {input.read_1} {input.read_2} > results/trimmed_reads/paired_end/{wildcards.paired_reads}/{wildcards.paired_reads}.trimmed.fastq.gz
		/usr/bin/time -v --output=results/mash_sketch/paired_end/{wildcards.paired_reads}/{wildcards.paired_reads}.bench_mash mash sketch results/trimmed_reads/paired_end/{wildcards.paired_reads}/{wildcards.paired_reads}.trimmed.fastq.gz 
		mv results/trimmed_reads/paired_end/{wildcards.paired_reads}/*.msh results/mash_sketch/paired_end/{wildcards.paired_reads}
		rm results/trimmed_reads/paired_end/{wildcards.paired_reads}/{wildcards.paired_reads}.trimmed.fastq.gz
		"""

rule seed_extender_paired_reads:
	"""
	Performing local seed extension of paired reads using perl script
	"""
	input:
		read_1="results/trimmed_reads/paired_end/{paired_reads}/{paired_reads}_1.trimmed.fastq.gz",
		read_2="results/trimmed_reads/paired_end/{paired_reads}/{paired_reads}_2.trimmed.fastq.gz"
	output:
		"results/seed_extender/paired_end/{paired_reads}/{paired_reads}.fasta"
	params:
		seed="-1",
		temp_dir="results/seed_extender/paired_end/{paired_reads}/{paired_reads}",
		db="prerequisites/resfinder_db/resfinder_db_all.fsa"
	envmodules:
		"tools",
		"kma/1.4.7",
		"anaconda3/2022.10",
		"spades/3.15.5",
		"fqgrep/20221222"
	shell:
		"""
		/usr/bin/time -v --output=results/seed_extender/paired_end/{wildcards.paired_reads}/{wildcards.paired_reads}.bench perl prerequisites/seed_extender/targetAsm.pl {params.seed} {params.temp_dir} {params.db} {input.read_1} {input.read_2}
		"""




rule download_single_end_reads:
	"""
	Downloading metagenomic raw single end reads from ENA using enaDataGet
	"""
	output:
		"results/raw_reads/single_end/{single_reads}/{single_reads}.fastq.gz",
		check_file_raw="results/raw_reads/single_end/{single_reads}/{single_reads}_check_file_raw.txt"
	params:
		outdir="results/raw_reads/single_end",
		type="fastq"
	envmodules:
		"tools",
		"anaconda3/2022.10",
		"enabrowsertools/1.1.0",
		"mariadb/10.4.17",
		"mariadb-connector-c/3.3.2"
	shell:
		"""
		/usr/bin/time -v --output=results/raw_reads/single_end/{wildcards.single_reads}/{wildcards.single_reads}.bench enaDataGet -f {params.type} -d {params.outdir} {wildcards.single_reads}
		bash check_status.sh results/raw_reads/single_end/{wildcards.single_reads}/{wildcards.single_reads}.bench {wildcards.single_reads} {rule}
		touch {output.check_file_raw}
		"""

rule trim_single_end_reads:
	"""
	Adapter trimming of raw paired end reads using fastp
	"""
	input:
		ancient("results/raw_reads/single_end/{single_reads}/{single_reads}.fastq.gz")
	output:
		"results/trimmed_reads/single_end/{single_reads}/{single_reads}.trimmed.fastq",
		check_file_trim="results/trimmed_reads/single_end/{single_reads}/{single_reads}_check_file_trim.txt"
	params:
		overlap_diff_limit="1",
		average_qual="20",
		length_required="50",
		cut_tail="--cut_tail",
		h="results/trimmed_reads/single_end/{single_reads}/{single_reads}.html",
		j="results/trimmed_reads/single_end/{single_reads}/{single_reads}.json"
	envmodules:
		"tools",
		"fastp/0.23.2",
		"mariadb/10.4.17",
		"mariadb-connector-c/3.3.2"
	shell:
		"""
		/usr/bin/time -v --output=results/trimmed_reads/single_end/{wildcards.single_reads}/{wildcards.single_reads}.bench fastp -i {input} -o {output} --overlap_diff_limit {params.overlap_diff_limit} --average_qual {params.average_qual} --length_required {params.length_required} {params.cut_tail} -h {params.h} -j {params.j}
		bash check_status.sh results/trimmed_reads/single_end/{wildcards.single_reads}/{wildcards.single_reads}.bench {wildcards.single_reads} {rule}
		touch {output.check_file_trim}
		"""

rule kma_single_end_reads_mOTUs:
	"""
	Mapping raw single reads for identifying AMR using KMA with mOTUs db
	"""
	input: 
		ancient("results/trimmed_reads/single_end/{single_reads}/{single_reads}.trimmed.fastq")
	output:
		"results/kma_mOTUs/single_end/{single_reads}/{single_reads}.res",
		"results/kma_mOTUs/single_end/{single_reads}/{single_reads}.mapstat",
		check_file_kma_mOTUs="results/kma_mOTUs/single_end/{single_reads}/{single_reads}_check_file_kma.txt"
	params:
		db="/home/databases/metagenomics/db/mOTUs_20221205/db_mOTU_20221205",
		outdir="results/kma_mOTUs/single_end/{single_reads}/{single_reads}",
		kma_params="-mem_mode -ef -1t1 -apm p -oa -matrix"
	envmodules:
		"tools",
		"kma/1.4.12a",
		"samtools/1.16",
		"mariadb/10.4.17",
		"mariadb-connector-c/3.3.2"
	shell:
		"""
		/usr/bin/time -v --output=results/kma_mOTUs/single_end/{wildcards.single_reads}/{wildcards.single_reads}.bench kma -i {input} -o {params.outdir} -t_db {params.db} {params.kma_params}
		rm results/kma_mOTUs/single_end/{wildcards.single_reads}/*.aln
		gzip results/kma_mOTUs/single_end/{wildcards.single_reads}/{wildcards.single_reads}.fsa
		bash check_status.sh results/kma_mOTUs/single_end/{wildcards.single_reads}/{wildcards.single_reads}.bench {wildcards.single_reads} {rule}
		touch {output.check_file_kma_mOTUs}
		"""

rule kma_single_end_reads_panRes:
	"""
	Mapping raw single reads for identifying AMR using KMA with panres db
	"""
	input: 
		ancient("results/trimmed_reads/single_end/{single_reads}/{single_reads}.trimmed.fastq")
	output:
		"results/kma_panres/single_end/{single_reads}/{single_reads}.res",
		"results/kma_panres/single_end/{single_reads}/{single_reads}.mat.gz",
		"results/kma_panres/single_end/{single_reads}/{single_reads}.mapstat",
		"results/kma_panres/single_end/{single_reads}/{single_reads}.bam",
		check_file_kma_panres="results/kma_panres/single_end/{single_reads}/{single_reads}_check_file_kma.txt"
	params:
		db="/home/databases/metagenomics/db/panres_20230313/panres_20230313",
		outdir="results/kma_panres/single_end/{single_reads}/{single_reads}",
		kma_params="-ef -1t1 -nf -vcf -sam -matrix"
	envmodules:
		"tools",
		"kma/1.4.12a",
		"samtools/1.16",
		"mariadb/10.4.17",
		"mariadb-connector-c/3.3.2"
	shell:
		"""
		/usr/bin/time -v --output=results/kma_panres/single_end/{wildcards.single_reads}/{wildcards.single_reads}.bench kma -i {input} -o {params.outdir} -t_db {params.db} {params.kma_params} |samtools fixmate -m - -|samtools view -u -bh -F 4|samtools sort -o results/kma_panres/single_end/{wildcards.single_reads}/{wildcards.single_reads}.bam
		rm results/kma_panres/single_end/{wildcards.single_reads}/*.aln
		gzip results/kma_panres/single_end/{wildcards.single_reads}/{wildcards.single_reads}.fsa
		bash check_status.sh results/kma_panres/single_end/{wildcards.single_reads}/{wildcards.single_reads}.bench {wildcards.single_reads} {rule}
		touch {output.check_file_kma_panres}
		"""

rule kma_single_end_reads_virulence_finder:
	"""
	Mapping raw single reads for identifying AMR using KMA with virulence_finder db
	"""
	input: 
		ancient("results/trimmed_reads/single_end/{single_reads}/{single_reads}.trimmed.fastq")
	output:
		"results/kma_virulence/single_end/{single_reads}/{single_reads}.res",
		"results/kma_virulence/single_end/{single_reads}/{single_reads}.mat.gz",
		"results/kma_virulence/single_end/{single_reads}/{single_reads}.mapstat",
		check_file_kma_virulence="results/kma_virulence/single_end/{single_reads}/{single_reads}_check_file_kma.txt"
	params:
		db="prerequisites/virulence_finder_db/virulence_finder_db.fsa",
		outdir="results/kma_virulence/single_end/{single_reads}/{single_reads}",
		kma_params="-ef -1t1 -nf -vcf -matrix"
	envmodules:
		"tools",
		"kma/1.4.12a",
		"samtools/1.16",
		"mariadb/10.4.17",
		"mariadb-connector-c/3.3.2"
	shell:
		"""
		/usr/bin/time -v --output=results/kma_virulence/single_end/{wildcards.single_reads}/{wildcards.single_reads}.bench kma -i {input} -o {params.outdir} -t_db {params.db} {params.kma_params}
		rm results/kma_virulence/single_end/{wildcards.single_reads}/*.aln
		gzip results/kma_virulence/single_end/{wildcards.single_reads}/{wildcards.single_reads}.fsa
		bash check_status.sh results/kma_virulence/single_end/{wildcards.single_reads}/{wildcards.single_reads}.bench {wildcards.single_reads} {rule}
		touch {output.check_file_kma_virulence}
		"""   

rule mash_sketch_single_end_reads:
	"""
	Creation of mash sketches of single end reads using mash
	"""
	input:
		ancient("results/trimmed_reads/single_end/{single_reads}/{single_reads}.trimmed.fastq")
	output:
		out="results/mash_sketch/single_end/{single_reads}/{single_reads}.trimmed.fastq.msh",
		check_file_mash="results/mash_sketch/single_end/{single_reads}/{single_reads}_check_file_mash.txt"
	envmodules:
		"tools",
		"mash/2.3",
		"mariadb/10.4.17",
		"mariadb-connector-c/3.3.2"
	shell:
		"""
		/usr/bin/time -v --output=results/mash_sketch/single_end/{wildcards.single_reads}/{wildcards.single_reads}.bench mash sketch -k 31 -s 10000 -o {output.out} -r {input}
		bash check_status.sh results/mash_sketch/single_end/{wildcards.single_reads}/{wildcards.single_reads}.bench {wildcards.single_reads} {rule}
		touch {output.check_file_mash}
		"""

rule seed_extender_single_reads:
	"""
	Performing local seed extension of paired reads using perl script
	"""
	input:
		ancient("results/trimmed_reads/single_end/{single_reads}/{single_reads}.trimmed.fastq")
	output:
		"results/seed_extender/single_end/{single_reads}/{single_reads}.fasta.gz",
		"results/seed_extender/single_end/{single_reads}/{single_reads}.gfa.gz",
		"results/seed_extender/single_end/{single_reads}/{single_reads}.frag.gz",
		"results/seed_extender/single_end/{single_reads}/{single_reads}.frag_raw.gz",
		check_file_seed="results/seed_extender/single_end/{single_reads}/{single_reads}_check_file_seed.txt"
	params:
		seed="-1",
		temp_dir="results/seed_extender/single_end/{single_reads}/{single_reads}",
		db="prerequisites/resfinder_db/resfinder_db_all.fsa"
	envmodules:
		"tools",
		"kma/1.4.12a",
		"anaconda3/2022.10",
		"spades/3.15.5",
		"fqgrep/0.0.3",
		"mariadb/10.4.17",
		"mariadb-connector-c/3.3.2"
	shell:
		"""
		/usr/bin/time -v --output=results/seed_extender/single_end/{wildcards.single_reads}/{wildcards.single_reads}.bench perl prerequisites/seed_extender/targetAsm.pl {params.seed} {params.temp_dir} {params.db} {input}
		gzip results/seed_extender/single_end/{wildcards.single_reads}/{wildcards.single_reads}.fasta
		gzip results/seed_extender/single_end/{wildcards.single_reads}/{wildcards.single_reads}.gfa
		bash check_status.sh results/seed_extender/single_end/{wildcards.single_reads}/{wildcards.single_reads}.bench {wildcards.single_reads} {rule}
		touch {output.check_file_seed}
		"""

rule cleanup_single_end_reads:
	"""
	Removing unwanted files
	"""
	input:
		check_file_raw="results/raw_reads/single_end/{single_reads}/{single_reads}_check_file_raw.txt",
		check_file_trim="results/trimmed_reads/single_end/{single_reads}/{single_reads}_check_file_trim.txt",
		check_file_kma_mOTUs="results/kma_mOTUs/single_end/{single_reads}/{single_reads}_check_file_kma.txt",
		check_file_kma_panres="results/kma_panres/single_end/{single_reads}/{single_reads}_check_file_kma.txt",
		check_file_kma_virulence="results/kma_virulence/single_end/{single_reads}/{single_reads}_check_file_kma.txt",
		check_file_mash="results/mash_sketch/single_end/{single_reads}/{single_reads}_check_file_mash.txt",
		check_file_seed="results/seed_extender/single_end/{single_reads}/{single_reads}_check_file_seed.txt"
	output:
		check_file_clean_final1="results/raw_reads/single_end/{single_reads}/check_clean_raw.txt",
		check_file_clean_final2="results/trimmed_reads/single_end/{single_reads}/check_clean_trim.txt"
	params:
		check_file_clean_raw1="results/raw_reads/single_end/{single_reads}/{single_reads}.fastq.gz",
		check_file_clean_trim1="results/trimmed_reads/single_end/{single_reads}/{single_reads}.trimmed.fastq"
	shell:
		"""
		cd results/raw_reads/single_end/{wildcards.single_reads}
		rm *.gz
		cd ../../../../
		touch {params.check_file_clean_raw1}
		touch {output.check_file_clean_final1}
		cd results/trimmed_reads/single_end/{wildcards.single_reads}
		rm *.fastq
		cd ../../../../
		touch {params.check_file_clean_trim1}
		touch {output.check_file_clean_final2}
		"""

rule download_paired_end_reads:
	"""
	Downloading metagenomic raw paired end reads from ENA using enaDataGet
	"""
	output:
		"results/raw_reads/paired_end/{paired_reads}/{paired_reads}_1.fastq.gz",
		"results/raw_reads/paired_end/{paired_reads}/{paired_reads}_2.fastq.gz",
		check_file_raw="results/raw_reads/paired_end/{paired_reads}/{paired_reads}_check_file_raw.txt"
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
		bash check_status.sh results/raw_reads/paired_end/{wildcards.paired_reads}/{wildcards.paired_reads}.bench {wildcards.paired_reads} {rule}
		touch {output.check_file_raw}
		"""

rule trim_paired_end_reads:
	"""
	Adapter trimming of raw paired end reads using fastp
	"""
	input:
		in1=ancient("results/raw_reads/paired_end/{paired_reads}/{paired_reads}_1.fastq.gz"),
		in2=ancient("results/raw_reads/paired_end/{paired_reads}/{paired_reads}_2.fastq.gz")
	output:
		out1="results/trimmed_reads/paired_end/{paired_reads}/{paired_reads}_1.trimmed.fastq",
		out2="results/trimmed_reads/paired_end/{paired_reads}/{paired_reads}_2.trimmed.fastq",
		singleton="results/trimmed_reads/paired_end/{paired_reads}/{paired_reads}_singleton.trimmed.fastq",
		check_file_trim="results/trimmed_reads/paired_end/{paired_reads}/{paired_reads}_check_file_trim.txt"
	params:
		overlap_diff_limit="1",
		average_qual="20",
		length_required="50",
		cut_tail="--cut_tail",
		out_merge="results/trimmed_reads/paired_end/{paired_reads}/{paired_reads}_merged.trimmed.fastq",
		h="results/trimmed_reads/paired_end/{paired_reads}/{paired_reads}.html",
		j="results/trimmed_reads/paired_end/{paired_reads}/{paired_reads}.json"
	envmodules:
		"tools",
		"fastp/0.23.2"
	shell:
		"""
		/usr/bin/time -v --output=results/trimmed_reads/paired_end/{wildcards.paired_reads}/{wildcards.paired_reads}.bench fastp -i {input.in1} -I {input.in2} -o {output.out1} -O {output.out2} --merge --merged_out {params.out_merge} --unpaired1 {output.singleton} --unpaired2 {output.singleton} --overlap_diff_limit {params.overlap_diff_limit} --average_qual {params.average_qual} --length_required {params.length_required} {params.cut_tail} -h {params.h} -j {params.j}
		cat {params.out_merge} >> {output.singleton}
		rm {params.out_merge}
		bash check_status.sh results/trimmed_reads/paired_end/{wildcards.paired_reads}/{wildcards.paired_reads}.bench {wildcards.paired_reads} {rule}
		touch {output.check_file_trim}
		"""

rule kma_paired_end_reads_mOTUs:
    	"""
    	Mapping raw paired reads for identifying AMR using KMA with mOTUs db
    	"""
    	input: 
         	read_1=ancient("results/trimmed_reads/paired_end/{paired_reads}/{paired_reads}_1.trimmed.fastq"),
        	read_2=ancient("results/trimmed_reads/paired_end/{paired_reads}/{paired_reads}_2.trimmed.fastq"),
        	read_3=ancient("results/trimmed_reads/paired_end/{paired_reads}/{paired_reads}_singleton.trimmed.fastq")
    	output:
        	"results/kma_mOTUs/paired_end/{paired_reads}/{paired_reads}.res",
        	"results/kma_mOTUs/paired_end/{paired_reads}/{paired_reads}.mapstat",
        	check_file_kma_mOTUs="results/kma_mOTUs/paired_end/{paired_reads}/{paired_reads}_check_file_kma.txt"
	params:
		db="/home/databases/metagenomics/db/mOTUs_20221205/db_mOTU_20221205",
		outdir="results/kma_mOTUs/paired_end/{paired_reads}/{paired_reads}",
		kma_params="-mem_mode -ef -1t1 -apm p -oa -matrix"
	envmodules:
		"tools",
		"kma/1.4.12a",
		"samtools/1.16"
	shell:
		"""
		/usr/bin/time -v --output=results/kma_mOTUs/paired_end/{wildcards.paired_reads}/{wildcards.paired_reads}.bench kma -ipe {input.read_1} {input.read_2} -i {input.read_3} -o {params.outdir} -t_db {params.db} {params.kma_params}
		rm results/kma_mOTUs/paired_end/{wildcards.paired_reads}/*.aln
		gzip results/kma_mOTUs/paired_end/{wildcards.paired_reads}/{wildcards.paired_reads}.fsa
		bash check_status.sh results/kma_mOTUs/paired_end/{wildcards.paired_reads}/{wildcards.paired_reads}.bench {wildcards.paired_reads} {rule}
		touch {output.check_file_kma_mOTUs}
		"""

rule kma_paired_end_reads_panRes:
	"""
	Mapping raw paired reads for identifying AMR using KMA with panres db
	"""
	input: 
		read_1=ancient("results/trimmed_reads/paired_end/{paired_reads}/{paired_reads}_1.trimmed.fastq"),
		read_2=ancient("results/trimmed_reads/paired_end/{paired_reads}/{paired_reads}_2.trimmed.fastq"),
		read_3=ancient("results/trimmed_reads/paired_end/{paired_reads}/{paired_reads}_singleton.trimmed.fastq")
	output:
		"results/kma_panres/paired_end/{paired_reads}/{paired_reads}.res",
		"results/kma_panres/paired_end/{paired_reads}/{paired_reads}.mat.gz",
		"results/kma_panres/paired_end/{paired_reads}/{paired_reads}.mapstat",
		"results/kma_panres/paired_end/{paired_reads}/{paired_reads}.bam",
		check_file_kma_panres="results/kma_panres/paired_end/{paired_reads}/{paired_reads}_check_file_kma.txt"
	params:
		db="/home/databases/metagenomics/db/panres_20230313/panres_20230313",
		outdir="results/kma_panres/paired_end/{paired_reads}/{paired_reads}",
		kma_params="-ef -1t1 -nf -vcf -sam -matrix"
	envmodules:
		"tools",
		"kma/1.4.12a",
		"samtools/1.16"
	shell:
		"""
		/usr/bin/time -v --output=results/kma_panres/paired_end/{wildcards.paired_reads}/{wildcards.paired_reads}.bench kma -ipe {input.read_1} {input.read_2} -i {input.read_3} -o {params.outdir} -t_db {params.db} {params.kma_params} |samtools fixmate -m - -|samtools view -u -bh -F 4|samtools sort -o results/kma_panres/paired_end/{wildcards.paired_reads}/{wildcards.paired_reads}.bam
		rm results/kma_panres/paired_end/{wildcards.paired_reads}/*.aln
		gzip results/kma_panres/paired_end/{wildcards.paired_reads}/{wildcards.paired_reads}.fsa
		bash check_status.sh results/kma_panres/paired_end/{wildcards.paired_reads}/{wildcards.paired_reads}.bench {wildcards.paired_reads} {rule}
		touch {output.check_file_kma_panres}
		"""

rule mash_sketch_paired_end_reads:
	"""
	Creation of mash sketches of paired end reads using mash
	"""
	input:
		read_1=ancient("results/trimmed_reads/paired_end/{paired_reads}/{paired_reads}_1.trimmed.fastq"),
		read_2=ancient("results/trimmed_reads/paired_end/{paired_reads}/{paired_reads}_2.trimmed.fastq"),
		read_3=ancient("results/trimmed_reads/paired_end/{paired_reads}/{paired_reads}_singleton.trimmed.fastq")
	output:
		out="results/mash_sketch/paired_end/{paired_reads}/{paired_reads}.trimmed.fastq.msh",
		check_file_mash="results/mash_sketch/paired_end/{paired_reads}/{paired_reads}_check_file_mash.txt"
	envmodules:
		"tools",
		"mash/2.3"
	shell:
		"""
		/usr/bin/time -v --output=results/mash_sketch/paired_end/{wildcards.paired_reads}/{wildcards.paired_reads}.bench_mash cat {input.read_1} {input.read_2} {input.read_3} | mash sketch -k 31 -s 10000 -I {wildcards.paired_reads} -C Paired -r -o {output.out} -
		bash check_status.sh results/mash_sketch/paired_end/{wildcards.paired_reads}/{wildcards.paired_reads}.bench {wildcards.paired_reads} {rule}
		touch {output.check_file_mash}
		"""

rule seed_extender_paired_reads:
	"""
	Performing local seed extension of paired reads using perl script
	"""
	input:
		read_1=ancient("results/trimmed_reads/paired_end/{paired_reads}/{paired_reads}_1.trimmed.fastq"),
		read_2=ancient("results/trimmed_reads/paired_end/{paired_reads}/{paired_reads}_2.trimmed.fastq"),
		read_3=ancient("results/trimmed_reads/paired_end/{paired_reads}/{paired_reads}_singleton.trimmed.fastq")
	output:
		"results/seed_extender/paired_end/{paired_reads}/{paired_reads}.fasta.gz",
		"results/seed_extender/paired_end/{paired_reads}/{paired_reads}.gfa.gz",
		"results/seed_extender/paired_end/{paired_reads}/{paired_reads}.frag.gz",
		"results/seed_extender/paired_end/{paired_reads}/{paired_reads}.frag_raw.gz",
		check_file_seed="results/seed_extender/paired_end/{paired_reads}/{paired_reads}_check_file_seed.txt"
	params:
		seed="-1",
		temp_dir="results/seed_extender/paired_end/{paired_reads}/{paired_reads}",
		db="prerequisites/resfinder_db/resfinder_db_all.fsa"
	envmodules:
		"tools",
		"kma/1.4.7",
		"anaconda3/2022.10",
		"spades/3.15.5",
		"fqgrep/0.0.3"
	shell:
		"""
		/usr/bin/time -v --output=results/seed_extender/paired_end/{wildcards.paired_reads}/{wildcards.paired_reads}.bench perl prerequisites/seed_extender/targetAsm.pl {params.seed} {params.temp_dir} {params.db} {input.read_1} {input.read_2} {input.read_3}
		gzip results/seed_extender/paired_end/{wildcards.paired_reads}/{wildcards.paired_reads}.fasta
		gzip results/seed_extender/paired_end/{wildcards.paired_reads}/{wildcards.paired_reads}.gfa
		bash check_status.sh results/seed_extender/paired_end/{wildcards.paired_reads}/{wildcards.paired_reads}.bench {wildcards.paired_reads} {rule}
		touch {output.check_file_seed}
		"""

rule cleanup_paired_end_reads:
	"""
	Removing unwanted files
	"""
	input:
		check_file_raw="results/raw_reads/paired_end/{paired_reads}/{paired_reads}_check_file_raw.txt",
		check_file_trim="results/trimmed_reads/paired_end/{paired_reads}/{paired_reads}_check_file_trim.txt",
		check_file_kma_mOTUs="results/kma_mOTUs/paired_end/{paired_reads}/{paired_reads}_check_file_kma.txt",
		check_file_kma_panres="results/kma_panres/paired_end/{paired_reads}/{paired_reads}_check_file_kma.txt",
		check_file_mash="results/mash_sketch/paired_end/{paired_reads}/{paired_reads}_check_file_mash.txt",
		check_file_seed="results/seed_extender/paired_end/{paired_reads}/{paired_reads}_check_file_seed.txt"
	output:
		check_file_clean_final1="results/raw_reads/paired_end/{paired_reads}/check_clean_raw.txt",
		check_file_clean_final2="results/trimmed_reads/paired_end/{paired_reads}/check_clean_trim.txt"
	params:
		check_file_clean_raw1="results/raw_reads/paired_end/{paired_reads}/{paired_reads}_1.fastq.gz",
		check_file_clean_raw2="results/raw_reads/paired_end/{paired_reads}/{paired_reads}_2.fastq.gz",
		check_file_clean_trim1="results/trimmed_reads/paired_end/{paired_reads}/{paired_reads}_1.trimmed.fastq",
		check_file_clean_trim2="results/trimmed_reads/paired_end/{paired_reads}/{paired_reads}_2.trimmed.fastq",
		check_file_clean_trim3="results/trimmed_reads/paired_end/{paired_reads}/{paired_reads}_singleton.trimmed.fastq"
	shell:
		"""
		cd results/raw_reads/paired_end/{wildcards.paired_reads}
		rm *.gz
		cd ../../../../
		touch {params.check_file_clean_raw1}
		touch {params.check_file_clean_raw2}
		touch {output.check_file_clean_final1}
		cd results/trimmed_reads/paired_end/{wildcards.paired_reads}
		rm *.fastq
		cd ../../../../
		touch {params.check_file_clean_trim1}
		touch {params.check_file_clean_trim2}
		touch {params.check_file_clean_trim3}
		touch {output.check_file_clean_final2}
		"""

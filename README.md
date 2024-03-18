# **Snakemake for ATACseq**

A snakemake-based workflow for ATAC-seq data analysis and report

## **Author**

[Zhuofei Xu](https://www.researchgate.net/profile/Zhuofei-Xu-4)

## **Bookmarks**

* [Backgroud](#background)
* [Usage](#usage)
* [Citation](#citation)


## **Background**

The workflow is an all-in-one analysis and report system. Users can only provide sample data files in the pre-defined file path, and edit some basic metadata (e.g. sample names, group names) in the configuration file (config.yaml). The workflow has the following advantages:

* [x] Automation: Don't need manually execute command lines of individual analysis steps. May be dozens of steps, it will be boring if a programmer executes these commands one by one. Prerequisite is that the developers should be familiar with the I/O files of each task.
* [x] Reproducibility
* [x] Portability: It supports standard operations for software portability, configuration, installation in the computer devices by the users with analytical tasks.
* [x] Extendability: It allows the developers to add more analysis modules into the toolkits for software update and upgradation.

The workflow performs the following analysis tasks:

* quality examination of raw fastq reads for each sample_r?.fq.gz file
* quality trimming of raw reads
* mapping reads per sample to the reference genome
* removing duplicated reads in the bam files
* filtering of low quality reads from the bam files
* peak calling
* peak annotation
* Enrichment analysis of the genes adjacent to the peaks

## **Usage**

Running the commands below can get a HTML-format analysis report from the raw data of all samples.

```
$ conda activate atacenv1
$ snakemake -c 2 -p -s workflow/Snakefile
```

The configuration files and raw data related to a test running of the workflow are deposited in this respository, as well as the final resulting report file and some intermediate processing files for a reproducible goal.

The resulting report file is [ATACseq_report.html](https://github.com/tigerxu/SnakemakeATACSeq/blob/main/example/result/ATACseq_report.html) under the directory 'result'.

The framework plot of the program running is shown below 

![ATAC-seq](example/ATAC.png)


###  **Some preparation prior to running the workflow**

```
$ mamba create -n atacenv1
$ mamba activate atacenv1
$ mamba install snakemake
```

The path and file names of the raw samples are written into the file **config/config.yaml**. The other sample metadata and group assignment info are also configured in this file, as well as some preprocessed files required by running tools, like genome index needed by bowtie2, bwa, star.

```
# the paths below need to replaced with the corresponding paths in your server
workdir: ./result
PE: true
sample:
  liver_rep1:
    r1: /path/to/sample/files/ENCFF288CVJ.fastq.gz
    r2: /path/to/sample/files/ENCFF888ZZV.fastq.gz
  liver_rep2:                
    r1: /path/to/sample/files/ENCFF883SEZ.fastq.gz
    r2: /path/to/sample/files/ENCFF035OMK.fastq.gz
  heart_rep1:                
    r1: /path/to/sample/files/ENCFF279LMU.fastq.gz
    r2: /path/to/sample/files/ENCFF820PVO.fastq.gz
  heart_rep2:                
    r1: /path/to/sample/files/ENCFF823XXU.fastq.gz
    r2: /path/to/sample/files/ENCFF518FYP.fastq.gz


## config/config.yaml

bwt2_idx: /path-to-the-btw2-genome-index/mm10

## config/config.yaml

genome: mm


OrgDb: org.Mm.eg.db
txdb: TxDb.Mmusculus.UCSC.mm10.knownGene

## config/config.yaml
diffGroup:
    lh:
      control:
        - liver_rep1
        - liver_rep2
      case:
        - heart_rep1
        - heart_rep2
```

Create a file named as **Snakefile**. 
```
$ touch workflow/Snakefile
```

Write all the command line operations required by the workflow in the file **Snakefile**. The program ***snakemake*** will execute the content in this file.

```
## workflow/Snakefile

# edit a configuration file in yaml or json format
configfile: "config/config.yaml"
# set the current directory as the working directory
workdir: config["workdir"]

## get the sample names from the config.yaml file
SAMPLES = config["sample"].keys()

## set two configuration for paired or single end reads according to the information set in config.yaml file
## generate two output files if "PE:true" present in the config.yaml for R1 and R2 reads
if config["PE"]:
    ENDS = ["r1", "r2"]
else:
    ENDS = ["se"]

## get the group names for differential comparison analysis
DIFFGROUPS = ["lh"]


raw_fq_qc_zips = expand("02fqc/raw/{sample}_{end}_fastqc.zip", sample=SAMPLES, end=ENDS)
## if the last rule performed by trim_gorale, then must add the files generated by trim_gorale
clean_fq_files = expand("01seq/clean/{sample}_r1_val_1.fq.gz", sample=SAMPLES)
align_bams = expand("03align/{sample}.bam", sample=SAMPLES)
filter_bams = expand("03align/{sample}.filter.bam", sample=SAMPLES)

peak_anno = expand("05peakanno/{sample}_peak_anno.csv", sample=SAMPLES)
diff_peak_result = expand("06diffpeak/{dgroup}_result.csv", dgroup = DIFFGROUPS)



rule all:
    input:
        raw_fq_qc_zips,
        #clean_fq_files,
        #align_bams,
        #filter_bams,
        peak_anno,
        diff_peak_result,
        "ATACseq_report.html"

# in the 'sample' block, in each of the 'sample' subblock, for the line of 'r1' or 'r2', get the value, i.e. the path and the name of the fastq file
def get_fq(wildcards):
    return config["sample"][wildcards.sample][wildcards.end]


rule rename:
    input:
        get_fq
    output:
        "01seq/raw/{sample}_{end}.fq.gz"
    shell:
        "ln -s {input} {output}"


## workflow/rules/fastqc.smk

rule raw_fq:
    input: 
        raw = rules.rename.output,
    output:
        "02fqc/raw/{sample}_{end}_fastqc.zip",  
    threads: 1        
    log:
        "logs/fastqc/raw/{sample}_{end}.log",
    shell:
        """
        bash -c '
        . $HOME/.bashrc # if not loaded automatically
        conda activate atacenv1
        fastqc -o 02fqc/raw -f fastq -t {threads} --noextract {input} 2> {log}
        conda deactivate'
        """

## workflow/rules/trimming.smk 

if config["PE"]:
    rule trim:
        input:
            "01seq/raw/{sample}_r1.fq.gz",
            "01seq/raw/{sample}_r2.fq.gz"
        output:
            "01seq/clean/{sample}_r1_val_1.fq.gz",
            "01seq/clean/{sample}_r2_val_2.fq.gz"   
        threads: 2 
        log:
            "logs/trim/{sample}.log"          
        shell:
            """
            bash -c '
            . $HOME/.bashrc # if not loaded automatically
            conda activate atacenv2
            trim_galore -j {threads} -q 25 --phred33 --length 36 --stringency 3 -o 01seq/clean --paired {input} 2> {log}
            conda deactivate'
            """
else:
    rule trim:
        input:
            "01seq/raw/{sample}_se.fq.gz"
        output:
            "01seq/clean/{sample}_se_trimmed.fq.gz"             
        threads: 2 
        log:
            "logs/trim/{sample}.log"          
        shell:
            """
            bash -c '
            . $HOME/.bashrc # if not loaded automatically
            conda activate atacenv2
            trim_galore -j {threads} -q 25 --phred33 --length 36 --stringency 3 -o 01seq/clean --paired {input} 2> {log}
            conda deactivate'
            """

## workflow/rules/bowtie2.smk 


if config["PE"]:
    rule btw2_map:
        input:
            rules.trim.output
        output:
            "03align/{sample}.bam" 
        threads: 2 
        log:
            "logs/bowtie2/{sample}.log"
        params:
            idx = config['bwt2_idx']
        shell:
            """
            bash -c '
            . $HOME/.bashrc # if not loaded automatically
            conda activate atacenv2
            bowtie2 -X2000 --mm -x {params} --no-unal --seed 100 -p {threads} -1 {input[0]} -2 {input[1]} 2> {log} | samtools sort -O bam -o {output}
            conda deactivate'
            """
            
else:
    rule btw2_map:
        input:
            rules.trim.output
        output:
            "03align/{sample}.bam" 
        threads: 2 
        log:
            "logs/bowtie2/{sample}.log"
        params:
            idx = config['bwt2_idx']
        shell:
            """
            bash -c '
            . $HOME/.bashrc # if not loaded automatically
            conda activate atacenv2
            bowtie2 -X2000 --mm -x {params} --no-unal --seed 100 -p {threads} -U {input} 2> {log} | samtools sort -O bam -o {output} && samtools index {output} -@ {threads}
            conda deactivate'
            """
            
## workflow/rules/bamfilter.smk 

## delete duplication reads
rule rmdup:
    input:
        rules.btw2_map.output
    output:
        "03align/{sample}.rmdup.bam"
    log:
        "logs/bamfilter/{sample}.rmdup.log"
    params:
        mode = "" if config["PE"] else "-s"
    shell:
            """
            bash -c '
            . $HOME/.bashrc # if not loaded automatically
            conda activate atacenv2
            samtools rmdup {params.mode} --output-fmt BAM {input} {output} 2> {log}
            conda deactivate'
            """

rule filter_bam:
    input:
        rules.rmdup.output
    output:
        "03align/{sample}.filter.bam"
    threads: 2
    log: 
        "logs/bamfilter/{sample}.filter.log"
    params:
        mode = "" if config["PE"] else "-s"
    shell:
            """
            bash -c '
            . $HOME/.bashrc # if not loaded automatically
            conda activate atacenv2
            samtools view -@ {threads} -q 20 -h {input} | grep -v -P '\\tchrM\\t' | samtools view -Sb -o {output}
            conda deactivate'
            """

## workflow/rules/callpeak.smk 

rule macs2_callpeak:
    input:
        rules.filter_bam.output
    output:
        "04callpeak/{sample}_peaks.narrowPeak"
    params:
        np = "04callpeak/{sample}", 
        fp = "BAMPE" if config["PE"] else "",
        gp = config["genome"]
    log:
        "logs/callpeak/{sample}.log"
    shell:
        """
            bash -c '
            . $HOME/.bashrc # if not loaded automatically
            conda activate atacenv2
            macs2 callpeak -t {input[0]} -g {params.gp} -f {params.fp} -n {params.np} -B -q 0.05 2> {log}
            conda deactivate'
        """



## workflow/rules/peak_anno.smk 

rule peak_annotate:
    input:
        "04callpeak/{sample}_peaks.narrowPeak"
    output:
        "05peakanno/{sample}_peak_anno.csv",
    params:
        outdir = "05peakanno"
    script:
        "scripts/peak_annotate.R"


def get_diff_control_sn(wildcards):
    return config["diffGroup"][wildcards.dgroup]["control"]

def get_diff_case_sn(wildcards):
    return config["diffGroup"][wildcards.dgroup]["case"]


def get_diff_control_bam(wildcards):
    sn = get_diff_control_sn(wildcards)
    bams = [f"03align/{i}.filter.bam" for i in  sn]
    return bams

def get_diff_case_bam(wildcards):
    sn = get_diff_case_sn(wildcards)
    bams = [f"03align/{i}.filter.bam" for i in  sn]
    return bams

def get_diff_control_peak(wildcards):
    sn = get_diff_control_sn(wildcards)
    peaks = [f"04callpeak/{i}_peaks.narrowPeak" for i in  sn]
    return peaks

def get_diff_case_peak(wildcards):
    sn = get_diff_case_sn(wildcards)
    peaks = [f"04callpeak/{i}_peaks.narrowPeak" for i in  sn]
    return peaks


rule peak_diff:
    input:
        control_bam = get_diff_control_bam,
        case_bam = get_diff_case_bam,
        control_peak = get_diff_control_peak,
        case_peak = get_diff_case_peak
    output:
        "06diffpeak/{dgroup}_result.csv",
    params:
        control_sn = get_diff_control_sn,
        case_sn = get_diff_case_sn      
    script:
        "scripts/peak_diff.R"


### workflow/rules/make_report.smk
rule make_report:
    input:
        peak_anno,
        diff_peak_result
    output:
        "ATACseq_report.html",
    params:
        samples = SAMPLES,
        diffgroups = DIFFGROUPS,
        peak_dir = "05peakanno",
        diffpeak_dir = "06diffpeak"
    script:
        "scripts/make_report.Rmd"

```



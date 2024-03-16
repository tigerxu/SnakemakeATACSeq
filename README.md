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

###  **Some preparation prior to running the workflow**

```
$ mamba create -n atacenv1
$ mamba activate atacenv1
$ mamba install snakemake
```

The path and file names of the raw samples are written into the file **config/config.yaml**.

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





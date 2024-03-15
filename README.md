# ***A snakemake-based workflow for ATAC-seq data analysis and report***

## **Index**

* [Backgroud](#background)

The workflow is an all-in-one analysis and report system. Users can only provide sample data files in the pre-defined file path, and edit some basic metadata (e.g. sample names, group names) in the configuration file (config.yaml). The workflow has the following advantages:

* [x] Automation: Don't need manually execute command lines of individual analysis steps. Prerequisite is that the developers should be familiar with the I/O files of each task.
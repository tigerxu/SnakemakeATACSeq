pacman::p_load(DiffBind)
output <- snakemake@output[[1]]
control_sn <- snakemake@params$control_sn
case_sn <- snakemake@params$case_sn
sns <- c(control_sn, case_sn)
bams <- c(snakemake@input$control_bam, snakemake@input$case_bam)
peaks <- c(snakemake@input$control_peak, snakemake@input$case_peak)
samples <- data.frame("SampleID"  = sns,
                      "Tissue"    = "all",
                      "Factor"    = c(rep("A", length(control_sn)), rep("B", length(case_sn))),
                      "Replicate" = c(seq(1, length(control_sn)), seq(1, length(case_sn))),
                      "bamReads"  = bams,
                      "Peaks"     = peaks,
                      "PeakCaller" = "narrow")
dbObj <- dba(sampleSheet=samples)
dbObj <- dba.count(dbObj , bUseSummarizeOverlaps=TRUE)
dbObj <- dba.normalize(dbObj)
dbObj <- dba.contrast(dbObj, categories=DBA_FACTOR, minMembers = 2)
dbObj <- dba.analyze(dbObj, method = DBA_DESEQ2)
dbObj.report <- dba.report(dbObj, th = 1, bUsePval = TRUE)
write.csv(dbObj.report, file=output)

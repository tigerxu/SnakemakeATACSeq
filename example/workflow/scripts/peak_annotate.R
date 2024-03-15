pacman::p_load(ChIPseeker, clusterProfiler, ggplot2, org.Mm.eg.db, TxDb.Mmusculus.UCSC.mm10.knownGene)

OrgDb <- snakemake@config$OrgDb
library(OrgDb, character.only = T)


txdb <- snakemake@config$txdb
library(txdb, character.only = T)
txdb <- eval(parse(text = txdb))

sn <- snakemake@wildcards$sample[1]
outdir <- snakemake@params$outdir


peak_path <- file.path(getwd(), snakemake@input[1])
peak_anno <- annotatePeak(peak_path, tssRegion=c(-3000, 3000), TxDb=txdb)
peak_anno_df <- as.data.frame(peak_anno)

peak_gene_df <- AnnotationDbi::select(eval(parse(text = OrgDb)),
                                      keytype = "ENTREZID",
                                      keys = peak_anno_df$geneId,
                                      columns = c("ENTREZID", "SYMBOL", "GENENAME"))


coln <- c("seqnames", "start", "end", "width", "V4", "V7", "annotation", "geneStart", "geneEnd", "geneLength",
          "geneStrand", "geneId", "transcriptId", "distanceToTSS", "SYMBOL")

new_peak_anno_df <- cbind(peak_anno_df, peak_gene_df)[, coln]
colnames(new_peak_anno_df)[c(5, 6)] <- c("peak_Id", "peak_score")



### save the peak annotations to a csv file per sample
peak.anno.fn <- sprintf("%s_peak_anno.csv", sn)
write.csv(new_peak_anno_df, file = file.path(outdir,  peak.anno.fn))    


### GO enrichment analysis of the genes covered by the peaks
all_ego <- enrichGO(
  gene          = new_peak_anno_df$geneId,
  keyType       = "ENTREZID",
  OrgDb         = OrgDb,
  ont           = "ALL",
  pAdjustMethod = "BH",
  pvalueCutoff  = 0.1,
  qvalueCutoff  = 0.1,
  readable      = TRUE,
  pool          = FALSE)
dir.create(file.path(outdir, "GO"), showWarnings = F)            
save.image(sprintf("%s/GO/%s_GO_BP.RData", outdir, sn))            
if (dim(as.data.frame(all_ego))[1] > 0){
  p <- dotplot(all_ego, split="ONTOLOGY", showCategory = 10)  + facet_grid(ONTOLOGY~., scale="free")
  ggsave(sprintf("%s/GO/%s_GO_all.pdf", outdir, sn), width=10, height = 10, plot=p)
  write.csv(as.data.frame(all_ego), file = sprintf("%s/GO/%s_GO_all.csv", outdir, sn))
  p
}

BP_ego <- enrichGO(
  gene          = new_peak_anno_df$geneId,
  keyType       = "ENTREZID",
  OrgDb         = OrgDb,
  ont           = "BP",
  pAdjustMethod = "BH",
  pvalueCutoff  = 0.1,
  qvalueCutoff  = 0.1,
  readable      = TRUE,
  pool          = FALSE)


if (dim(as.data.frame(BP_ego))[1]>0){
  BP_p <- dotplot(BP_ego, showCategory = 12) 
  ggsave(sprintf("%s/GO/%s_GO_BP.pdf", outdir, sn), width=10, height = 10, plot=BP_p)
  write.csv(as.data.frame(BP_ego), file = sprintf("%s/GO/%s_GO_BP.csv", outdir, sn))
}

CC_ego <- enrichGO(
  gene          = new_peak_anno_df$geneId,
  keyType       = "ENTREZID",
  OrgDb         = OrgDb,
  ont           = "CC",
  pAdjustMethod = "BH",
  pvalueCutoff  = 0.1,
  qvalueCutoff  = 0.1,
  readable      = TRUE,
  pool          = FALSE)
if (dim(as.data.frame(CC_ego))[1] > 0){
  CC_p <- dotplot(CC_ego, showCategory = 12) 
  ggsave(sprintf("%s/GO/%s_GO_CC.pdf", outdir, sn), width=10, height = 10, plot=CC_p)
  write.csv(as.data.frame(CC_ego), file = sprintf("%s/GO/%s_GO_CC.csv", outdir, sn))
}

MF_ego <- enrichGO(
  gene          = new_peak_anno_df$geneId,
  keyType       = "ENTREZID",
  OrgDb         = OrgDb,
  ont           = "MF",
  pAdjustMethod = "BH",
  pvalueCutoff  = 0.1,
  qvalueCutoff  = 0.1,
  readable      = TRUE,
  pool          = FALSE)
if (dim(as.data.frame(MF_ego))[1]>0){
  MF_p <- dotplot(MF_ego, showCategory = 12) 
  ggsave(sprintf("%s/GO/%s_GO_MF.pdf", outdir, sn), width=10, height = 10, plot=MF_p)
  write.csv(as.data.frame(MF_ego), file = sprintf("%s/GO/%s_GO_MF.csv", outdir, sn))
}

Rdata.out <- sprintf("%s/%s_anno.Rdata", outdir, sn)

save.image(Rdata.out)

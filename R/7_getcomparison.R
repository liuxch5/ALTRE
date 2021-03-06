#' Comparison of methods for identifying altered regulatory regions
#'
#' Creates a table to compare two methods of identifying altered regulatory
#' regions, one based on peak intensity, the other on peak presence as
#'  determined by hotspot calling algorithms.
#'
#' @param analysisresults analysisresults of countanalysis.
#' @param lfctypespecific log2fold change for type specific TSS-dists/TSS-proxs
#' @param lfcshared log2fold chance for shared TSS-dists/TSS-proxs
#' @param pvaltypespecific p-value for type specific TSS-dists/TSS-proxs
#' @param pvalshared p-value for shared TSS-dists/TSS-proxs
#'
#' @return matrix comparing the two methods of identifying altered regulatory
#' regions, one based on peak intensity, the other on peak presence as
#' determined by hotspot calling algorithms.
#' @examples
#' \dontrun{
#' csvfile <- loadCSVFile("DNaseEncodeExample.csv")
#' samplePeaks <- loadBedFiles(csvfile)
#' consensusPeaks <- getConsensusPeaks(samplepeaks = samplePeaks, minreps = 2)
#' TSSannot <- getTSS()
#' consensusPeaksAnnotated <- combineAnnotatePeaks(conspeaks = consensusPeaks,
#'    TSS = TSSannot,
#'    merge = TRUE,
#'    regionspecific = TRUE,
#'    distancefromTSSdist = 1500,
#'    distancefromTSSprox = 1000)
#' consensusPeaksCounts <- getCounts(annotpeaks = consensusPeaksAnnotated,
#'    sampleinfo = csvfile,
#'    reference = 'SAEC',
#'    chrom = 'chr21')
#' alteredPeaks <- countanalysis(counts = consensusPeaksCounts,
#'    pval = 0.01,
#'    lfcvalue = 1)
#' alteredPeaksCategorized <- categAltrePeaks(alteredPeaks,
#'    lfctypespecific = 1.5,
#'    lfcshared = 1.2,
#'    pvaltypespecific = 0.01,
#'    pvalshared = 0.05)
#' comparePeaksAnalysisResults <- comparePeaksAltre(alteredPeaksCategorized)
#' }
#' @export
#'
comparePeaksAltre <- function(analysisresults,
                              lfctypespecific = 1.5,
                              lfcshared = 1.2,
                              pvaltypespecific = 0.01,
                              pvalshared = 0.05){

  analysisresults_firstitem <- analysisresults[[1]]

  if (!is.data.frame(analysisresults_firstitem)) {
    stop("Make sure the output of the analysis is from categAltrePeaks() function")
  }

  #Make sure to names things are from the user-entered sample names
  allSamples <- colnames(analysisresults_firstitem)[12:13]
  reference <- analysisresults$reference
  compareresults <-  matrix(nrow = 9, ncol = 2)
  nonreference <-  allSamples[!(allSamples %in% reference)]

  if (length(nonreference) == 1) {
    string <- nonreference
    nonreferencestr <- nonreference
  } else {
    string <- c()
    for (i in 1:length(nonreference)) {
      or <- "and/or"
      if (i == length(nonreference)) {
        string <- paste(string, or, nonreference[i], sep = " ")
      } else {
        string <- paste(string, nonreference[i], sep = ", ")
      }
    }
    nonreferencestr <- substr(string, 3, nchar(string))
  }

  one <- c(rep(nonreferencestr, 3), rep(reference, 3), rep("Shared", 3))
  two <- rep(c("TSS-dists", "TSS-proxs", "all"), 3)

  matrixrownames <- paste(one, two)
  rownames(compareresults) <- matrixrownames
  colnames(compareresults) <- c("intensity", "peak")

  # create a matrix for my analysisresults_firstitem which says how mant of one-specific
  # total, two-specific TSS-proxs, etc.

  compareresults[1, 1] <-
    length(which(analysisresults_firstitem$log2FoldChange > lfctypespecific &
                   analysisresults_firstitem$padj < pvaltypespecific &
                   analysisresults_firstitem$region == "TSS-distal"))
  compareresults[2, 1] <-
    length(which(analysisresults_firstitem$log2FoldChange > lfctypespecific &
                   analysisresults_firstitem$padj <  pvaltypespecific &
                   analysisresults_firstitem$region == "TSS-proximal"))
  compareresults[3, 1] <-
    length(which(analysisresults_firstitem$log2FoldChange > lfctypespecific &
                   analysisresults_firstitem$padj <  pvaltypespecific))
  compareresults[4, 1] <-
    length(which(analysisresults_firstitem$log2FoldChange < -lfctypespecific &
                   analysisresults_firstitem$padj <  pvaltypespecific &
                   analysisresults_firstitem$region ==  "TSS-distal"))
  compareresults[5, 1] <-
    length(which(analysisresults_firstitem$log2FoldChange <  -lfctypespecific &
                   analysisresults_firstitem$padj <   pvaltypespecific &
                   analysisresults_firstitem$region ==  "TSS-proximal"))
  compareresults[6, 1] <-
    length(which(analysisresults_firstitem$log2FoldChange <   -lfctypespecific &
                   analysisresults_firstitem$padj <   pvaltypespecific))
  compareresults[7, 1] <-
    length(which((analysisresults_firstitem$log2FoldChange >= -lfcshared &
                    analysisresults_firstitem$log2FoldChange <= lfcshared) &
                   (analysisresults_firstitem$padj >=   pvalshared |
                      is.na(analysisresults_firstitem$padj)) &
                   analysisresults_firstitem$region == "TSS-distal"))
  compareresults[8, 1] <-
    length(which((analysisresults_firstitem$log2FoldChange >= -lfcshared &
                    analysisresults_firstitem$log2FoldChange <= lfcshared) &
                   (analysisresults_firstitem$padj >= pvalshared |
                      is.na(analysisresults_firstitem$padj)) &
                   analysisresults_firstitem$region == "TSS-proximal"))
  compareresults[9, 1] <-
    length(which((analysisresults_firstitem$log2FoldChange >= -lfcshared &
                    analysisresults_firstitem$log2FoldChange <= lfcshared) &
                   analysisresults_firstitem$padj >= pvalshared))

  typespecsub <- analysisresults_firstitem[, 11:ncol(analysisresults_firstitem)]

  referencesub <- as.matrix(analysisresults_firstitem[,  reference])
  nonreferencesub <- as.matrix(analysisresults_firstitem[,  nonreference])

  compareresults[1, 2] <-
    tssdistnonreference <-
    length(which(apply(nonreferencesub,
                       1,
                       function(x) {any(is.na(x) == FALSE)}) &
                   apply(referencesub, 1, function(x) {any(is.na(x))}) &
                   analysisresults_firstitem$region == "TSS-distal"))
  compareresults[2, 2] <-
    tssproxnonreference <-
    length(which(apply(nonreferencesub,
                       1,
                       function(x) {any(is.na(x) == FALSE)}) &
                   apply(referencesub, 1, function(x) {any(is.na(x))}) &
                   analysisresults_firstitem$region == "TSS-proximal"))
  compareresults[3, 2] <-
    allnonreference <-
    length(which(apply(nonreferencesub,
                       1,
                       function(x) {any(is.na(x) == FALSE)}) &
                   apply(referencesub,
                         1,
                         function(x) {any(is.na(x))})))
  compareresults[4, 2] <-
    tssdistreference <-
    length(which(apply(referencesub,
                       1,
                       function(x) { any(is.na(x) == FALSE)}) &
                   apply(nonreferencesub,
                         1,
                         function(x) { all(is.na(x))}) &
                   analysisresults_firstitem$region == "TSS-distal"))
  compareresults[5, 2] <-
    tssproxreference <-
    length(which(apply(referencesub,
                       1,
                       function(x) { any(is.na(x) == FALSE)}) &
                   apply(nonreferencesub,
                         1,
                         function(x) { all(is.na(x))}) &
                   analysisresults_firstitem$region == "TSS-proximal"))
  compareresults[6, 2] <-
    allreference <-
    length(which(apply(referencesub,
                       1,
                       function(x) { any(is.na(x) == FALSE)}) &
                   apply(nonreferencesub,
                         1,
                         function(x) { all(is.na(x))})))
  compareresults[7, 2] <-
    tssdistshared <-
    length(which(apply(referencesub,
                       1, function(x) {
                         any(is.na(x) == FALSE)
                       }) & apply(nonreferencesub, 1, function(x) {
                         any(is.na(x) == FALSE)
                       }) & analysisresults_firstitem$region == "TSS-distal"))
  compareresults[8, 2] <-
    tssproxshared <-
    length(which(apply(referencesub,
                       1, function(x) {
                         any(is.na(x) == FALSE)
                       }) & apply(nonreferencesub, 1, function(x) {
                         any(is.na(x) == FALSE)
                       }) & analysisresults_firstitem$region == "TSS-proximal"))
  compareresults[9, 2] <-
    allshared <-
    length(which(apply(referencesub,
                       1, function(x) {
                         any(is.na(x) == FALSE)
                       }) & apply(nonreferencesub, 1, function(x) {
                         any(is.na(x) == FALSE)
                       })))

  listToReturn <- list(compareresults = data.frame(Type=rownames(compareresults),
                       intensity=compareresults[,"intensity"],peak=compareresults[,"peak"]),
                       reference = reference)
  return(listToReturn)
}


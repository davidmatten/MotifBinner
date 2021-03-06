# Useful functions for applying functions to files or folders

#' Bins a given FASTA file and outputs each bin as a seperate file
#'
#' @param file_name The file name
#' @param add_uniq_id If True, an integer will be appended to
#' the end of each sequence's name so that all identical sequences in a bin
#' gets the same number and sequences who are not identical will get different
#' numbers.
#' @param number_of_front_bases_to_discard The number of bases to remove from
#' the front of the sequence
#' @param prefix See ?extract_motifs
#' @param suffix See ?extract_motifs
#' @param motif_length See ?extract_motifs
#' @param max.mismatch See ?extract_motifs
#' @param fixed See ?extract_motifs
#' @param write_files If this is a directory, the bins will be written to that
#' folder as FASTA files.
#' @export

bin_file <- function(file_name = "~/projects/MotifBinner/data/CAP177_2040_v1merged.fastq", 
                     add_uniq_id = TRUE,
                     number_of_front_bases_to_discard = 28,
                     prefix = "CCAGCTGGTTATGCGATTCTMARGTG",
                     suffix = "CTGAGCGTGTGGCAAGGCCC",
                     motif_length = 9,
                     max.mismatch = 5,
                     fixed = FALSE,
                     write_files = FALSE
                     ){

  x <- readFastq(file_name)
  x <- x@sread
  x <- padAndClip(x, IRanges(start = number_of_front_bases_to_discard, 
                             end=width(x)), 
                  Lpadding.letter="+", Rpadding.letter="+")
  seq_data <- x
  y <- extract_motifs(seq_data, prefix, suffix, motif_length, max.mismatch, fixed)

  bin_seqs <- bin_by_name(y$matched_seq, add_uniq_id)

  if (write_files != FALSE){
    dir.create(write_files, showWarnings=FALSE)
    print('writing files')
    for (i in names(bin_seqs)){
      n_seqs <- sprintf("%05.0f", length(bin_seqs[[i]]))
      writeXStringSet(bin_seqs[[i]],
                      file.path(write_files, paste0("Bin_", n_seqs, 
                                                    "_", i, ".FASTA")))
    }
  }
  return(bin_seqs)
}

#' Reads a classified binned file and splits it into bins
#' @param file_name Name of the file to process
#' @param prefixes The prefixes that indicate the different bins
#' @export

read_classified_binned_file <- function(file_name, prefixes = c('src', 'out')){
  # file_name <- "/home/phillipl/projects/MotifBinner/data/sample_classified_bins/classified/Bin_00030_CTGGAACCT.FASTA"
  seq_dat <- readDNAStringSet(file_name)
  bins <- list()
  for (prefix in prefixes){
    bins[[prefix]] <- character(0)
    for (i in 1:length(seq_dat)){
      seq_name <- names(seq_dat)[i]
      if (length(grep(paste0('^', prefix), seq_name)) == 1){
        bins[[prefix]] <- c(bins[[prefix]], as.character(seq_dat[i]))
      }
    }
  }
  stopifnot(length(seq_dat) == sum(unlist(lapply(bins, length))))
  return(bins)
}

#' Reads in all files from a folder, assuming that they are classified binned
#' files
#' @param binned_folder The folder containing the binned classified files
#' @export

dput_classified_binned_folder <- function(binned_folder){
  # binned_folder <- "/home/phillipl/projects/MotifBinner/data/sample_classified_bins/binfiasco"
  files <- list.files(binned_folder)
  all_binned_files <- list()
  for (file_name in files){
    file_path <- file.path(binned_folder, file_name)
    bins <- read_classified_binned_file(file_path)
    all_binned_files[[file_name]] <- bins
  }
  return(all_binned_files)
}

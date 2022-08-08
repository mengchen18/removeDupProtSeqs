############# app setting #############
# root directory
root <- "/home/shiny/projects"


############# dependencies and functions #############
library(seqinr)
library(fastmatch)
library(shinyFiles)
library(DT)
library(shinybusy)

removeFastaDuplicate <- function(file) {
  outfile <- sub("(.fasta|.fa|.fas)$", "_noDup.fasta", file)
  
  ff <- read.fasta(file, seqtype = "AA", as.string = TRUE)
  seqs <- sapply(ff, c)
  
  i <- !duplicated(seqs)
  seqs_unique <- ff[i]
  seqs_dup <- ff[!i]
  
  an_dup <- sapply(seqs_dup, attr, "Annot")
  an_unique <- sapply(seqs_unique, attr, "Annot")
  
  map <- sapply(seqs_dup, fmatch, table = seqs_unique)
  v <- rep(NA, length(seqs_unique))
  v[map] <- an_dup
  m <- cbind(seq_keep = an_unique, seq_remove = v)
  
  #####
  an <- sub("^>", "", sapply(seqs_unique, attr, "Annot"))
  write.fasta(sequences = seqs_unique, names = an, file.out = outfile, as.string = TRUE, nbchar = 70)
  m
}


############# App start #############

ui <- fluidPage(
  fluidRow(
    column(12, h3('CleanFastaDup - Removing duplicated fasta sequences in a fasta file: ')),
    column(12, 
           h5('How to use:'),
           h5('  1. Select a fasta file;'),
           h5('  2. Click "RUN!", then the fasta without duplicates will be saved in the same folder as the original input fasta, with "noDup.fasta".')),
    column(2, shinyFiles::shinyFilesButton('fasta', 'Select a fasta file', 'Extension should be one of: fasta, fa, faa, fas', FALSE)),
    column(10, verbatimTextOutput("path")),
    column(2, actionButton(inputId = "run", label = "RUN!")),
    column(10, verbatimTextOutput("stats")),
    column(12, hr()),
    column(12, DT::DTOutput("summary"))
  )
)

server <- function(input, output, session) {
  
  ############## folder - need R & W permission ###########
  roots <- c(dr = root)
  shinyFiles::shinyFileChoose(input, id = "fasta", roots = roots, defaultRoot = "dr", filetypes=c('', 'fasta', "fa", "fas", "faa"))
  filePath <- reactive({
    req( input$fasta )
    req( !is.integer(input$fasta) )
    path <- parseFilePaths(roots, input$fasta) 
    path$datapath[1]
  })
  output$path <- renderText( filePath() )
  
  tab <- eventReactive(input$run, {
    shinybusy::show_modal_spinner(text = "Removing duplicates!")
    t <- removeFastaDuplicate(filePath())
    shinybusy::remove_modal_spinner()
    t
  })
  
  output$stats <- renderText({
    req(tt <- tab())
    n_kept <- sum(!is.na(tt[, 1]))
    n_rm <- sum(!is.na(tt[, 2]))
    n_tot <- n_kept + n_rm
    sprintf("Number of sequences kept: %s; Number of sequences removed: %s; Number of total sequences: %s.", n_kept, n_rm, n_tot)
  })
  
  output$summary <- DT::renderDT(
    DT::datatable(tab(), rownames= FALSE)
  )
}

shinyApp(ui, server)

############# App end #############

#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#
setwd("~/Text Mining/HumanFactor2")


library(shiny)
library(tm)
library(wordcloud)
library(memoise)
library(rsconnect)
library(reader)
library(tidyverse)
library(dplyr)
library(pdftools)
library(magrittr)
library(tidyverse) # Manipulacao eficiente de dados
library(tidytext) # Manipulacao eficiente de texto
library(textreadr) # Leitura de pdf para texto
library(wordcloud) # Grafico nuvem de palavras
library(igraph)
library(ggraph)
library(ggplot2)
library(RRPP)
library(SnowballC)
library(glue)
library(purrr)
library(memoise)



arquivoPdf_1 <- "~/Text Mining/HumanFactor2/relatorios/Abandono_producao_P-34.pdf"
##arquivoPdf_2 <- "~/HumanFactor2/relatorios/Balroamento_obito-SS-83.pdf"
##arquivoPdf_3 <- "~/HumanFactor2/relatorios/ExplosaoSM_11-02-15.pdf"


# you can use an url or a path that leads to a pdf dcument


# extract text
txt_output <- pdftools::pdf_text(arquivoPdf_1) %>%
    paste(sep = " ") %>%
    stringr::str_replace_all(fixed("\n"), " ") %>%
    stringr::str_replace_all(fixed("\r"), " ") %>%
    stringr::str_replace_all(fixed("\t"), " ") %>%
    stringr::str_replace_all(fixed("\""), " ") %>%
    paste(sep = " ", collapse = " ") %>%
    stringr::str_squish() %>%
    stringr::str_replace_all("- ", "") 


# The list of valid books
books <<- list("Abandono_producao" = "parada")

#"Balroamento_obito" = "balroamento",
#"Explosao_Naufragio" = "Naufragio"



# Using "memoise" to automatically cache the results
getTermMatrix <- memoise(function(book) {
    # Careful not to let just any name slip in here; a
    # malicious user could manipulate this value.
    if (!(book %in% books))
        stop("Unknown book")
    
    text <- readLines(sprintf(txt_output, book),
                      encoding="UTF-8")

    
    myCorpus = Corpus(VectorSource(text))
    myCorpus = tm_map(myCorpus, content_transformer(tolower))
    myCorpus = tm_map(myCorpus, removePunctuation)
    myCorpus = tm_map(myCorpus, removeNumbers)
    myCorpus = tm_map(myCorpus, removeWords,
                      c(stopwords("SMART"), "thy", "thou", "thee", "the", "and", "but"))
    
    myDTM = TermDocumentMatrix(myCorpus,
                               control = list(minWordLength = 1))
    
    m = as.matrix(myDTM)
    
    sort(rowSums(m), decreasing = TRUE)
    
})



# Define UI for application that draws a histogram
ui <- fluidPage(
    # Application title
    titlePanel("Word Cloud"),
    
    sidebarLayout(
        # Sidebar with a slider and selection inputs
        sidebarPanel(
            selectInput("Escolha", "Escolha um documento:",
                        choices = books),
            actionButton("update", "Change"),
            hr(),
            sliderInput("freq",
                        "Minimum Frequency:",
                        min = 1,  max = 50, value = 15),
            sliderInput("max",
                        "Maximum Number of Words:",
                        min = 1,  max = 300,  value = 100)
        ),
        
        # Show Word Cloud
        mainPanel(
            plotOutput("plot")
        )
    )
)


    server <- function(input, output, session) {
        # Define a reactive expression for the document term matrix
        terms <- reactive({
            # Change when the "update" button is pressed...
            input$update
            # ...but not for anything else
            isolate({
                withProgress({
                    setProgress(message = "Processing corpus...")
                    getTermMatrix(input$selection)
                })
            })
        })
        
        # Make the wordcloud drawing predictable during a session
        wordcloud_rep <- repeatable(wordcloud)
        
        output$plot <- renderPlot({
            v <- terms()
            wordcloud_rep(names(v), v, scale=c(4,0.5),
                          min.freq = input$freq, max.words=input$max,
                          colors=brewer.pal(8, "Dark2"))
        })
    }

# Run the application 
shinyApp(ui = ui, server = server)

#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

rsconnect::setAccountInfo(name='vivianesch', token='99089EE69C2A20B8E669E3E5C2ED72B5', secret='MLL72ZVfzPrzFr5qsY9rgxS9MxeBct0Xd9ONjCkj')
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

arquivoPdf_1 <- "~/Text Mining/HumanFactor2/relatorios/Abandono_producao_P-34.pdf"
arquivoPdf_2 <- "~/Text Mining/HumanFactor2/relatorios/Balroamento_obito-SS-83.pdf"
arquivoPdf_3 <- "~/Text Mining/HumanFactor2/relatorios/Explosao_Naufragio_P-36.pdf"


.LimpaOrganiza <- function(arquivoPdf) {
    Texto <- arquivoPdf %>% 
        read_pdf() %>%
        as.tibble() %>% 
        select(text)
    return(Texto)
}



Abandono_producao <- .LimpaOrganiza(arquivoPdf_1)
Balroamento_obito <- .LimpaOrganiza(arquivoPdf_2)
Explosao_Naufragio <- .LimpaOrganiza(arquivoPdf_3)



# The list of valid books
books <<- list("Abandono_producao" = "parada",
               "Balroamento_obito" = "balroamento",
               "Explosao_Naufragio" = "Naufragio")


    
    text <- Abandono_producao
    
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



# Define UI for application that draws a histogram
ui <- fluidPage(
    # Application title
    titlePanel("Word Cloud"),
    
    sidebarLayout(
        # Sidebar with a slider and selection inputs
        sidebarPanel(
            selectInput("selection", "Choose a book:",
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



    # Text of the books downloaded from:
    # A Mid Summer Night's Dream:
    #  http://www.gutenberg.org/cache/epub/2242/pg2242.txt
    # The Merchant of Venice:
    #  http://www.gutenberg.org/cache/epub/2243/pg2243.txt
    # Romeo and Juliet:
    #  http://www.gutenberg.org/cache/epub/1112/pg1112.txt
    
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

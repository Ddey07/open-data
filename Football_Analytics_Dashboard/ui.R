#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#

library(shiny)

matches = readRDS("matches.rds")
matches_list = matches$Versus

# Define UI for application that draws a histogram
shinyUI(fluidPage(
  
  # Application title
  titlePanel("HUD"),
  
  selectInput("teams", label = "Select Match", choices = matches_list),
  
  selectInput("GPsp", label = "Plot Type", choices = c("xGP", "XSP")),
  
  textOutput("possession"),
  
  
  plotOutput("plots"),
  
  hr(),
  
  fluidRow(
    column(1,offset = 1,
           actionButton("Increment","Next Possession"),
           actionButton("Decrement", "Previous Possession")
           )
  )

  )
)


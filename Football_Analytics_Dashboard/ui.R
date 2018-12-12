#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#

library(shiny)

# Define UI for application that draws a histogram
shinyUI(fluidPage(
  
  # Application title
  titlePanel("HUD"),
  
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


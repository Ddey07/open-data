#
# This is the server logic of a Shiny web application. You can run the 
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#

library(shiny)
library(ggplot2)
library(ggsoccer)
library(gridExtra)

#load data
game_dat = readRDS("graph_df.rds")
home_team = unique(game_dat$home_team.home_team_name)
away_team = unique(game_dat$away_team.away_team_name)

# Define server logic required to draw a histogram
shinyServer(function(input, output) {
  
  
    poss_tracker = reactiveValues(poss_num = 0)
    
    observeEvent(input$Increment, {
      poss_tracker$poss_num = poss_tracker$poss_num + 1
      plot_dat = game_dat[1:poss_tracker$poss_num + 1,]
    })
    
    observeEvent(input$Decrement, {
      poss_tracker$poss_num = poss_tracker$poss_num - 1
      plot_dat = game_dat[1:poss_tracker$poss_num - 1,]
    })
    
    output$possession = renderText({
        paste("Possession: ", poss_tracker$poss_num+1)
    })
    
    
    
    
    output$plots = renderPlot({
      xgp = ggplot() +
        theme_dark()
      team1 = ggplot(pass_data) +
        annotate_pitch() +
        theme_pitch() +
        xlim(-1, 101) +
        ylim(-5, 101) +
        ggtitle(home_team)
      team2 = ggplot(pass_data) +
        annotate_pitch() +
        theme_pitch() +
        xlim(-1, 101) +
        ylim(-5, 101) +
        ggtitle(away_team)
      
      grid.arrange(grobs = list(xgp, team1, team2), ncols = 2, widths = c(2,1,1))
    })

  
})

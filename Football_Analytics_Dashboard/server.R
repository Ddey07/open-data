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
library(dplyr)

#load data
game_dat = readRDS("graph_df.rds")

matches = readRDS("matches.rds")
pc.data = readRDS("pc.data.rds")
match.results = readRDS("match.results.rds")


pass_data <- data.frame(x = c(24, 18, 64, 78, 53),
                        y = c(43, 55, 88, 18, 44),
                        x2 = c(34, 44, 81, 85, 64),
                        y2 = c(40, 62, 89, 44, 28))

plot.team=function(teams){
  teams.data = pc.data %>% filter(poss.team %in% teams & def.team %in% teams)
  teams.data$playmins= cumsum(teams.data$timespan)
  poss.percent = teams.data %>% group_by(poss.team) %>% summarise(time=sum(timespan)) %>% mutate(time=time*100/max(teams.data$playmins))
  result = match.results %>% filter(home_team %in% teams & away_team %in% teams)
  match.info=data.frame(poss.percent,goals=c(result$home_score, result$away_score)[sapply(poss.percent$poss.team,function(x){grep(x,c(result$home_team,result$away_team))})])
  
  teams.data$xSP[is.na(teams.data$xSP)]=0
  teams.data$xGP[is.na(teams.data$xGP)]=0
  
  team1=match.info$poss.team[1]
  team2=match.info$poss.team[2]
  match.info$time=round(match.info$time,0)
  
  teams.data <- teams.data %>% mutate(team1.xSP= (-xSP) * (def.team==team1) + (xSP) * (poss.team==team1),
                                      team2.xSP= (-xSP) * (def.team==team2) + (xSP) * (poss.team==team2),
                                      team1.xGP= (-xGP) * (def.team==team1) + (xSP) * (poss.team==team1),
                                      team2.xGP= (-xGP) * (def.team==team2) + (xSP) * (poss.team==team2))
  
  teams.data %>% select(team1.xSP,team2.xSP,playmins) %>% mutate(team1.xSP=cumsum(team1.xSP),team2.xSP=cumsum(team2.xSP)) %>% 
    gather(key=team, value=value, - playmins) %>% ggplot(aes(x=playmins/60,y=value,col=team)) + geom_line() + scale_color_manual(name="Team",labels=c(team1,team2),values=c("Orange","Black")) +
    labs(title=paste0("(",match.info$time[1],"%) ",team1," ",match.info$goals[1],"-",match.info$goals[2]," ",team2, " (",match.info$time[2],"%)"), subtitle="Possession shown in brackets",x="Playing minutes", y="Expected shot difference", caption="Excluding penalties, own goals and big mistakes") + theme(plot.title = element_text(hjust = 0.5),plot.subtitle=element_text(face="italic")) 
  
}

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
    

    
    observeEvent(input$teams, {
      home_team = filter(matches,Versus == input$teams) %>%
                        select(home) %>% pull
      away_team = filter(matches,Versus == input$teams) %>%
        select(away) %>% pull
      
      output$plots = renderPlot({
        xgp = plot.team(c(home_team, away_team))
        
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

  
})

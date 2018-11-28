rm(list=ls())


library(plyr)
library(tidyverse)
library("jsonlite")
library(soccermatics)
library(ggsoccer)


#Loading .RData
load("./data/Full_event_compiled.RData")

press.data <- all.data %>% filter(type.name=="Pressure") %>% select(match_id,index, period, timestamp,possession_team.id, duration, possession_team.name, team.id, team.name, player.id, player.name, start.x, start.y, home_team.home_team_name, away_team.away_team_name, home_score, away_score) %>%
                mutate(team_type=ifelse(team.name==home_team.home_team_name,"Home","Away"))

match.results <- press.data %>% group_by(match_id) %>% summarise(home_score=unique(home_score), away_score=unique(away_score), home_team=unique(home_team.home_team_name), away_team=unique(away_team.away_team_name), home_count=table(team_type)[2], away_count=table(team_type)[1]) %>% 
                 mutate(home_percent= home_count/(home_count + away_count))

for(i in 1:nrow(match.results)){
  if(match.results$home_score[i]==match.results$away_score[i]){
  match.results$result[i]="Draw"
  }
  else{
    match.results$result[i]=ifelse(match.results$home_score[i] > match.results$away_score[i], "Home", "Away")
  }
}

ggplot(match.results,aes(x=result,y=home_percent)) + geom_boxplot()



  
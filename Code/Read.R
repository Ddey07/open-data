rm(list=ls())

library(plyr)
library(tidyverse)
library("jsonlite")
library(soccermatics)
library(ggsoccer)

#Reading match data
setwd("./data/matches")
match.json.1 <- jsonlite::fromJSON(list.files()[1],flatten = TRUE)
#Reading world cup data
match.json.2 <- jsonlite::fromJSON(list.files()[2],flatten = TRUE)
match.data <- rbind(match.json.1,match.json.2)[-1,]


#Reading events datas
event.path <- "../events"
setwd(event.path)

file.id <- list.files() %in% as.character(paste0(match.data[,1],".json")) 
file.list <- list.files()[file.id]

event.data <- jsonlite::fromJSON(file.list[1], flatten = TRUE)
event.data$match_id <- rep(as.numeric(substr(file.list[1],1,4)),nrow(event.data))

for(i in 2:length(file.list)){
  json.data <- jsonlite::fromJSON(file.list[i], flatten = TRUE)
  match.id.event <- as.numeric(substr(file.list[i],1,4))
  json.data$match_id <- rep(match.id.event,nrow(json.data))
  event.data <- rbind.fill(event.data,json.data)
  print(i)
}

all.data <- merge(event.data,match.data)

#Splitting locations 
for(i in 1:nrow(all.data)){
  if(is.null(all.data$location[[i]])){
    all.data$start.x[i] <- NA
    all.data$start.y[i] <- NA
    all.data$pass.end.x[i] <- NA
    all.data$pass.end.y[i] <- NA
  } else if (is.null(all.data$pass.end_location[[i]])) {
    all.data$start.x[i] <- all.data$location[[i]][1]
    all.data$start.y[i] <- all.data$location[[i]][2]
    all.data$pass.end.x[i] <- NA
    all.data$pass.end.y[i] <- NA
    
  } else {
    all.data$start.x[i] <- all.data$location[[i]][1]
    all.data$start.y[i] <- all.data$location[[i]][2]
    all.data$pass.end.x[i] <- all.data$pass.end_location[[i]][1]
    all.data$pass.end.y[i] <- all.data$pass.end_location[[i]][2]
  }
}

#all.data$start.x <- all.data$location

drops <- c("location","pass.end_location")
all.data <- all.data[,!(names(all.data) %in% drops)]

#write.csv(all.data,file="NWSL_event_compiled.csv")

#Saving into .RData
save(all.data,file="../Full_event_compiled.RData")

rm(list=ls())

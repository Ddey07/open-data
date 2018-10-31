rm(list=ls())


library(plyr)
library(tidyverse)
library("jsonlite")
library(soccermatics)
library(ggsoccer)


#Loading .RData
load("./data/Full_event_compiled.RData")
#all.data <- all_data

###Measuring pass speeds
all.data <- all.data %>% mutate(pass.speed= pass.length/duration)
all.data$pass.speed[(all.data$pass.speed %in% boxplot.stats(all.data$pass.speed, coef=3)$out)] = NA

all.data$duration[(all.data$duration %in% boxplot.stats(all.data$duration, coef=1.5)$out)] = NA


all.data %>% group_by(player.id,match_id) %>% select(pass.length,pass.angle,pass.speed,pass.outcome.id,pass.outcome.name)

###Storing which position id means what 
position.info <- all.data %>% select(position.id,position.name) %>% unique
position.info <- position.info[-1,]
position.info <- position.info %>% arrange(position.id)


###Getting player positions and formation matchwise
position.data <- data.frame(player.id=numeric(), player.name=character(), position.name=character(), 
                            match_id= numeric(), team.id=numeric(), team.name=numeric(),tactics.formation=numeric(),
                            team.status=character())

for (i in unique(all.data$match_id)){
  all.data.match <- all.data %>% filter(match_id==i) 
  team1.id=all.data.match[1,]$team.id
  team1.name = all.data.match[1,]$team.name
  team1.formation=all.data.match[1,]$tactics.formation
  
  team2.id=all.data.match[2,]$team.id
  team2.name = all.data.match[2,]$team.name
  team2.formation=all.data.match[2,]$tactics.formation
  
  position.data <- rbind(position.data, data.frame(all.data.match$tactics.lineup[[1]][,c(2,3,5)],match_id=i, team.id=team1.id,team.name=team1.name,tactics.formation=team1.formation, team.status="Home"))
  position.data <- rbind(position.data, data.frame(all.data.match$tactics.lineup[[2]][,c(2,3,5)],match_id=i,team.id=team2.id,team.name=team2.name,tactics.formation=team2.formation, team.status="Away"))
}

####Getting substitution data
sub.data <- all.data %>% filter(!is.na(substitution.outcome.id)) %>% select(match_id, period, minute, timestamp,second, duration, 
                                                                            team.id, player.id, position.name, substitution.outcome.id, substitution.outcome.name, substitution.replacement.id)

sub.data$substitution.replacement.position <- position.data$position.name[match(sub.data$substitution.replacement.id,position.data$player.id)]


#####Extracting passing information
pass.sub <-   all.data[,which(unlist(lapply(names(all.data),function(x){grepl(pattern="pass",x)})))]

pass.data <- cbind(all.data %>% select(match_id, index, period, timestamp, minute, second, player.id, team.id, start.x, start.y, under_pressure,duration, play_pattern.name, type.name), 
                   pass.sub)

pass.data <- pass.data[!is.na(pass.data$pass.end.x),]
#Removing pass speed outliers
#pass.data$pass.speed[(pass.data$pass.speed %in% boxplot.stats(pass.data$pass.speed, coef=3)$out)] = NA

pass.data %>% group_by(pass.height.name) %>% select(pass.speed)

#####Extracting foul information
foul.sub <-   all.data[,which(unlist(lapply(names(all.data),function(x){grepl(pattern="foul",x)})))]

foul.data <- cbind(all.data %>% select(match_id, index, period, timestamp, minute, second, player.id, team.id, start.x, start.y, play_pattern.name, type.name), 
                   foul.sub)

foul.data <- foul.data[rowMeans(is.na(foul.sub)) != 1,]

######Shots data


shots.sub <-   all.data[,which(unlist(lapply(names(all.data),function(x){grepl(pattern="shot",x)})))]

shots.data <- cbind(all.data %>% select(match_id, index, period, timestamp, minute, second, player.id, team.id, start.x, start.y, play_pattern.name, type.name), 
                    shots.sub)

shots.data <- shots.data[!is.na(shots.data$shot.statsbomb_xg),]

###### Getting m minute data before shots ########
m <- 2
shots.pre <- list()

for(i in 1:nrow(shots.data)){
  shot.time <- strptime(shots.data$timestamp[i],format="%H:%M:%S")
  shot.period <- shots.data$period[i]
  all.data.shot <- subset(all.data,match_id==shots.data[i,]$match_id)
  all.data.shot$timestamp <- strptime(all.data.shot$timestamp,format="%H:%M:%S")
  shots.pre[[i]] <- subset(all.data.shot, as.numeric(timestamp - shot.time) <= 0 & as.numeric(timestamp - shot.time) > (-60*m) & period == shot.period & index <= shots.data$index[i])
}

res.x <- 30
res.y <- 16

D <- data.frame(x=runif(1000,0,120), y=runif(1000,0,80))
D <- within(D, {
  grp.x = cut(x, seq(0,120,by=res.x), labels = FALSE)
  grp.y = cut(y, seq(0,80,by=res.y), labels = FALSE)
}) %>% select(grp.x,grp.y) %>% mutate(grid.ind=paste0(grp.x,"_",grp.y)) 

D$grid.ind <- factor(D$grid.ind)

####attributes from shots m-minute window 
shotwindow.att <- function(i){
  shot.info <- tail(shots.pre[[i]],1)
  shot.possession <- subset(shots.pre[[i]], possession == shot.info$possession)
  attack.formation <- unique(subset(position.data, team.id == shot.info$team.id & match_id == shot.info$match_id)$tactics.formation)
  defence.formation <- unique(subset(position.data, team.id != shot.info$team.id & match_id == shot.info$match_id)$tactics.formation)
  time.to.shoot <- as.numeric(shot.info$timestamp - shot.possession$timestamp[1])
  distance.to.shot <- as.numeric(dist(rbind(c(shot.info$start.x,shot.info$start.y), c(shot.possession$start.x[1], shot.possession$start.y[1]))))
  speed.of.attack <- distance.to.shot/time.to.shoot
  shot.xG <- shot.info$shot.statsbomb_xg
  pressure.escaped <- nrow(subset(shot.possession, type.name=="Pressure")) 

  
  if(shot.info$start.x > 60){
    shot.possession$start.x= abs(shot.possession$start.x - 120)
    shot.possession$start.y= abs(shot.possession$start.y - 80)
  }
  
  location.grid <- within(shot.possession, {
    grp.x = cut(start.x, seq(0,120,by=res.x), labels = FALSE, include.lowest = TRUE)
    grp.y = cut(start.y, seq(0,80,by=res.y), labels = FALSE, include.lowest = TRUE)
  }) %>% select(grp.x,grp.y) %>% mutate(grid.ind=paste0(grp.x,"_",grp.y)) 
  
  shot.possession <- data.frame(shot.possession,location.grid)
  shot.possession$grid.ind <- factor(shot.possession$grid.ind, levels=levels(D$grid.ind))
  
  pressure.location <-unlist((shot.possession %>% select(-timestamp) %>% filter(type.name=="Pressure")%>% group_by(grid.ind) %>% 
                                  summarise(pressure.count=n()) %>% complete(grid.ind, fill = list(pressure.count= 0)))[,2])
  
  pass.location <-unlist((shot.possession %>% select(-timestamp) %>% filter(type.name=="Pass")%>% group_by(grid.ind) %>% 
    summarise(pass.count=n()) %>% complete(grid.ind, fill = list(pass.count= 0)))[,2])
  
  win.location <- head(shot.possession$grid.ind,1)
    
  covars <- t(data.frame(c(AF=attack.formation, DF=defence.formation,time.to.shoot=time.to.shoot, distance.to.shot=distance.to.shot, speed=speed.of.attack, xG=shot.xG, n.pressure=pressure.escaped, unlist(pressure.location), unlist(pass.location))))
  covars <- cbind(covars,win.location)
  return(covars)
}

###recording 2 minute frames from all shotwindows 
shots.att <- unlist(shotwindow.att(1))

for(i in 2:nrow(shots.data)){
  temp <- rbind(shots.att,shotwindow.att(i))
  shots.att <- temp
  #print(i)
}

shots.full <- data.frame(shots.data,shots.att)

shots.full$Goal <- shots.full$shot.outcome.name == "Goal"
shots.full$win.location <- relevel(factor(shots.full$win.location), ref=20)

shots.full$AF[shots.full$AF == 4141] = 451
shots.full$AF[shots.full$AF == 4411] = 442
shots.full$AF[shots.full$AF == 3421] = 343
shots.full$AF[shots.full$AF==451] = 4321

shots.full$DF[shots.full$DF == 4141] = 451
shots.full$DF[shots.full$DF == 4411] = 442
shots.full$DF[shots.full$DF == 3421] = 343
shots.full$DF[shots.full$DF==451] = 4321

##Fitting logistic to get grid-specific coefficients
fit <- glm(Goal ~ factor(AF) + xG + factor(DF)*factor(win.location), data=shots.full, family=binomial())
coef1 <- coef(fit,complete = TRUE)

grid.numeric <- data.frame(num=unique(as.numeric(D$grid.ind)),grid=unique(D$grid.ind))

x.seq <- seq(0,120,by=res.x)
y.seq <-seq(0,80,by=res.y) 

##Creating grid data
grid.numeric <- grid.numeric %>% arrange(num) %>% mutate(x.min=rep(x.seq[-length(x.seq)], each=length(y.seq)-1), 
                                         x.max=rep(x.seq[-1], each=length(y.seq)-1),
                                         y.min=rep(y.seq[-length(y.seq)], length(x.seq)-1),
                                         y.max=rep(y.seq[-1], length(x.seq)-1))


length.formation <- length(unique(shots.full$DF))
length.loc <- length(unique(shots.full$win.location)) - 2
remove <- 2*(length.formation-1) + 2 + length.loc
coef2 <- coef1[-(1:remove)]

formation <- c("3-5-2","4-3-3", "4-4-2","5-4-1","4-2-3-1","4-4-1")

coef2.df <- data.frame(coef=coef2, formation = rep(formation,length.loc), grid= rep(grid.numeric[-20,]$grid,each=6))

coef2.df <- data.frame(coef2.df, grid.numeric[-20,-2])

coef2.df %>% ggplot(aes(x=grid, y=coef, color=formation)) %>% geom_point()

coef3.df <- subset(coef2.df, formation != "5-4-1" & x.max <=80)
coef.quant <- with(coef3.df, cut(abs(coef), 
                             breaks=quantile(abs(coef), probs=seq(0,1, length=10), na.rm=TRUE), 
                             include.lowest=TRUE))
red.pal <- brewer.pal(9,"YlOrRd")
coef.quant <- red.pal[coef.quant]

coef3.df$col <- coef.quant

###Plotting heatmap of interaction coefficients
ggplot(coef3.df, aes(x=coef)) +
  annotate_pitch(x_scale = 1.2,
                 y_scale = 0.8,
                 colour = "gray70",
                 fill = "gray90") +facet_wrap(~formation) + 
  theme_pitch() +
  geom_rect(aes(xmin=x.min,xmax=x.max,ymin=y.min,ymax=y.max), alpha=0.3, fill=col)+ 
  labs(title="Heatmap of vulnerabilities according to formation", fill= "Vulnerability index") + scale_fill_manual(values=red.pal)  

###Finding preferred foot of all players
Mode <- function(x) {
  ux <- unique(x)
  ux[which.max(tabulate(match(x, ux)))]
}

prefer.foot <- all.data %>% filter(type.name=="Pass") %>% group_by(player.name) %>% summarise(Mode(pass.body_part.name))

names(prefer.foot)[2] <- "Foot"

pass.event <- all.data %>% filter(type.name=="Pass") %>% separate(related_events,into=c("rel.event1","rel.event2","rel.event3"), sep=",", fill="right", extra="merge")
#receive.event <- all.data %>% filter(type.name=="Ball Receipt*")

#pass.receive <- left_join(receive.event,pass.event,by=c("id"="rel.event1")) %>% filter(!is.na(pass.speed.y)) 

pass.sum <- pass.event %>% select(pass.length,pass.angle, pass.speed, pass.recipient.id, pass.recipient.name, pass.outcome.id,pass.outcome.name, pass.body_part.name, pass.height.name, player.name) %>%
                           filter(!is.na(pass.body_part.name))
pass.sum <- left_join(pass.sum,prefer.foot) %>% mutate(prefer.foot= (Foot==pass.body_part.name))
 

###### Use pass angle to determine favoured side and then see who passes onto the favoured side


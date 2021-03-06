library(httr)
library(jsonlite)
library(tidyverse)
library(lubridate)

# List of Teams with Info
teams <- GET("https://statsapi.web.nhl.com/api/v1/teams")
data <- fromJSON(rawToChar(teams$content))
teams <- as.data.frame(data$teams)



# List Flyers players and filter to those on roster
players <- GET("https://records.nhl.com/site/api/player/byTeam/4")
data <- fromJSON(rawToChar(players$content))
players <- as.data.frame(data$data)
flyers <- players%>%
  filter(onRoster == "Y")

# Claude Giroux

id <- 8473512

# Game data
gameGet <- GET("https://statsapi.web.nhl.com/api/v1/game/2019020053/feed/live")
data <- fromJSON(rawToChar(gameGet$content))
gameTbl <- as.data.frame(data$gameData)

# Filter to play level data
plays <- data$liveData$plays$allPlays

# Make a table of result column
result <- plays$result%>%
  select(eventTypeId)

# Isolate the players column
players <- plays%>%
  select(players)

# Isolate the coordinates column
coords <- plays$coordinates

# Combine the result (event type), involved players, and coordinates,
# then filter the events to shots only
shots <- cbind(result,players,coords)%>%
  filter(eventTypeId == "SHOT")


# Create a new data frame with seperate columns for shooter and goalie
df <- data.frame()
for(n in 1:nrow(shots)){
  shooter <- as.data.frame(shots$players[n])
  new <- data.frame("Shooter" = shooter$player$id[1],"Shooter_Name" = shooter$player$fullName[1], "Goalie"= shooter$player$id[2], "Goalie_Name"=shooter$player$fullName[2])
  df <- rbind(df,new)
}

# Add shooter and goalie columns back to original shot data frame
shotsDetail <- shots%>%
  select(eventTypeId,x,y)%>%
  cbind(df)%>%
  mutate(date = ymd_hms(gameTbl$datetime.dateTime),
         homeTeam = as.character(gameTbl$teams.home.name),
         awayTeam = as.character(gameTbl$teams.away.name))


# Add Game Info
date <- ymd_hms(gameTbl$datetime.dateTime)
homeTeam <- as.character(gameTbl$teams.home.name)
awayTeam <- as.character(gameTbl$teams.away.name)

goals <- cbind(result,players,coords)%>%
  filter(eventTypeId == "GOAL")


outDf <- 

# plotly
library(plotly)

# Symbols
vals <- schema(F)$traces$scatter$attributes$marker$symbol$values
vals <- grep("-", vals, value = T)

ax <- list(
  title = "",
  zeroline = FALSE,
  showline = FALSE,
  showticklabels = FALSE,
  showgrid = FALSE
)

p <- plot_ly() %>%
  add_markers(data = shotsDetail, x= ~x, y= ~y,
              hoverinfo = "text",
              text = ~paste("Shooter: ", Shooter_Name, "<br>",
                            "Goalie: ", Goalie_Name))%>%
  add_markers(x= goals$x, y=goals$y,marker = list(symbol = vals[13],
                                                  size = 10,
                                                  color = 'red',
                                                  line = list(color = "black",
                                                              width = 2)))%>%
  layout(
    images = list(
      list(source =  "https://raw.githubusercontent.com/armurray/NHL_Stats/master/img/rink_full.png",
           xref = "x",
           yref = "y",
           x = -100,
           y = 42.5,
           sizex = 200,
           sizey = 85,
           sizing = "stretch",
           opacity = 0.8,
           layer = "below"
      )
    ),
    xaxis = list(
      title = "",
      zeroline = FALSE,
      showline = FALSE,
      showticklabels = FALSE,
      showgrid = FALSE,
      range = c(-100,100)),
    yaxis = ax
  )

p




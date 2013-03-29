library(shiny)

library(XML)
library(gtools)

playersProfiles <- c()

EloExpectedScore <- function(rating1, rating2) {
    1 / (1 + 10 ^ ((rating2 - rating1) / 400))
}

getProb <- function(score, winPerc, drawPerc) {
    x <- score / (winPerc + 0.5 * drawPerc)

    win <- winPerc * x
    draw <- (score - win) * 2
    loss <- 1 - win - draw

    c(win, draw, loss)
}

getIntegerfromFactor <- function(f) {
    pattern <- "[0-9]+"

    n <- unclass(levels(f)[unclass(f)])
    as.numeric(regmatches(n, regexpr(pattern, n)))
}

getLastTourney <- function() {
    team4545Url <- "http://team4545league.org/"

    doc <- htmlParse(team4545Url)
    tableNodes <- getNodeSet(doc, "//table")
    table <- readHTMLTable(tableNodes[[1]])

    str <- as.character(table[1, 3])
    pattern <- ("T[0-9]+")
    tourney <- regmatches(str, regexpr(pattern, str))

    tourney
}

getPlayersProfiles <- function(tourney) {
    if (NROW(playersProfiles) != 0) {
        return
    }

    tourney <- tolower(tourney)
    team4545TournamentUrl <- "http://team4545league.org/tournament/"

    ratingsUrl <- paste(team4545TournamentUrl,
        "/", tourney, "/", tourney, "ratings.html", sep="")

    doc <- htmlParse(ratingsUrl)
    tableNodes <- getNodeSet(doc, "//table")

    table <- readHTMLTable(tableNodes[[2]])

    playersProfiles <<- table[1:(NROW(table) - 1), ]
}

getPlayersProfiles(getLastTourney())

getPlayerProfile <- function(player) {
    x <- playersProfiles
    rating = getIntegerfromFactor(x[x$Handle == player, ]$FixedRating)

    list(
        player=player,
        rating=rating
    )
}

getPlayersStats <- function(profile1, profile2) {
    team4545StatsUrl <- paste("http://team4545league.org/players/",
        "displayhist.php?player=", sep="")

    playersRating <- c(profile1$rating, profile2$rating)
    weakerPlayerColumn <- match(min(playersRating), playersRating)

    playersName <- c(profile1$player, profile2$player)
    playerName <- playersName[weakerPlayerColumn]

    statsUrl <- paste(team4545StatsUrl, playerName, sep="")
    doc <- htmlParse(statsUrl)
    tableNodes = getNodeSet(doc, "//table")

    if (NROW(tableNodes) > 0) {
        table <- readHTMLTable(tableNodes[[1]])
        n <- NROW(table)

        stats <- as.character(table[n, "Total"])
        stats <- as.numeric(strsplit(stats, " ")[[1]])

        total <- sum(stats)
        winPerc <- stats[1] / total
        drawPerc <- stats[2] / total
        lossPerc <- stats[3] / total

        if (weakerPlayerColumn == 1) {
            score <- EloExpectedScore(playersRating[1], playersRating[2])
        } else {
            score <- EloExpectedScore(playersRating[2], playersRating[1])
        }

        probs <- getProb(score, winPerc, drawPerc)

        c(probs, weakerPlayerColumn)
    } else {
        c(NA, NA, NA, 0)
    }
}

getTeamProbs <- function(gamesProbs) {
    results <- permutations(n=3, r=4, v=c(1, 0.5, 0), repeats.allowed=TRUE)
    teamResults <- rowSums(results)

    results <- permutations(n=3, r=4, repeats.allowed=TRUE)
    results[results==3] <- 0
    results[results==1] <- 3
    results[results==0] <- 1
    teamWins <- results[teamResults > 2, ]
    teamDraws <- results[teamResults == 2, ]

    probs <- apply(gamesProbs, 1, function(p) {
        if (p[4] == 1) {
            c(p[1], p[2], p[3], p[4])
        } else {
            c(p[3], p[2], p[1], p[4])
        }
    })
    probs <- t(probs)

    teamWinProb = sum(apply(teamWins, 1, function(outcomes) {
        probs[1, outcomes[1]] *
        probs[2, outcomes[2]] *
        probs[3, outcomes[3]] *
        probs[4, outcomes[4]]
    }))

    teamDrawProb = sum(apply(teamDraws, 1, function(outcomes) {
        probs[1, outcomes[1]] *
        probs[2, outcomes[2]] *
        probs[3, outcomes[3]] *
        probs[4, outcomes[4]]
    }))

    c(teamWinProb, teamDrawProb)
}

shinyServer(function(input, output) {

    game1PlayerAProfile <- reactive ({
        if (input$playerA1 != "") {
            getPlayerProfile(input$playerA1)
        }
    })
    game1PlayerBProfile <- reactive ({
        if (input$playerB1 != "") {
            getPlayerProfile(input$playerB1)
        }
    })
    game1Stats <- reactive({
        if (input$playerA1 != "" && input$playerB1 != "") {
            getPlayersStats(game1PlayerAProfile(), game1PlayerBProfile())
        } else {
            c(NA, NA, NA, 0)
        }
    })

    game2PlayerAProfile <- reactive ({
        if (input$playerA2 != "") {
            getPlayerProfile(input$playerA2)
        }
    })
    game2PlayerBProfile <- reactive ({
        if (input$playerB2 != "") {
            getPlayerProfile(input$playerB2)
        }
    })
    game2Stats <- reactive({
        if (input$playerA2 != "" && input$playerB2 != "") {
            getPlayersStats(game2PlayerAProfile(), game2PlayerBProfile())
        } else {
            c(NA, NA, NA, 0)
        }
    })

    game3PlayerAProfile <- reactive ({
        if (input$playerA3 != "") {
            getPlayerProfile(input$playerA3)
        }
    })
    game3PlayerBProfile <- reactive ({
        if (input$playerB3 != "") {
            getPlayerProfile(input$playerB3)
        }
    })
    game3Stats <- reactive({
        if (input$playerA3 != "" && input$playerB3 != "") {
            getPlayersStats(game3PlayerAProfile(), game3PlayerBProfile())
        } else {
            c(NA, NA, NA, 0)
        }
    })

    game4PlayerAProfile <- reactive ({
        if (input$playerA4 != "") {
            getPlayerProfile(input$playerA4)
        }
    })
    game4PlayerBProfile <- reactive ({
        if (input$playerB4 != "") {
            getPlayerProfile(input$playerB4)
        }
    })
    game4Stats <- reactive({
        if (input$playerA4 != "" && input$playerB4 != "") {
            getPlayersStats(game4PlayerAProfile(), game4PlayerBProfile())
        } else {
            c(NA, NA, NA, 0)
        }
    })

    teamProbs <- reactive({
        gamesProbs <- c()

        gamesProbs <- rbind(gamesProbs, game1Stats())
        gamesProbs <- rbind(gamesProbs, game2Stats())
        gamesProbs <- rbind(gamesProbs, game3Stats())
        gamesProbs <- rbind(gamesProbs, game4Stats())

        getTeamProbs(gamesProbs)
    })

    output_names <- c()
    output_names <- rbind(output_names, c("profileA1", "game1PlayerAProfile",
        "profileB1", "game1PlayerBProfile", "game1", "game1Stats"))
    output_names <- rbind(output_names, c("profileA2", "game2PlayerAProfile",
        "profileB2", "game2PlayerBProfile", "game2", "game2Stats"))
    output_names <- rbind(output_names, c("profileA3", "game3PlayerAProfile",
        "profileB3", "game3PlayerBProfile", "game3", "game3Stats"))
    output_names <- rbind(output_names, c("profileA4", "game4PlayerAProfile",
        "profileB4", "game4PlayerBProfile", "game4", "game4Stats"))

    apply(output_names, 1, function (out_name) {
        local({
            info_names <- c("Player", "Rating")
            my_out_name <- out_name[1]
            for (info_name in info_names) {
                local({
                    my_info_name <- info_name
                    end_out_name <- paste(my_out_name, my_info_name, sep = "")

                    output[[end_out_name]] <<- renderText({
                        my_profile <- get(out_name[2])()
                        my_profile[[tolower(my_info_name)]]
                    })
                })
            }
            my_out_name <- out_name[3]
            for (info_name in info_names) {
                local({
                    my_info_name <- info_name
                    end_out_name <- paste(my_out_name, my_info_name, sep = "")

                    output[[end_out_name]] <<- renderText({
                        my_profile <- get(out_name[4])()
                        my_profile[[tolower(my_info_name)]]
                    })
                })
            }

            info_names <- c("WinProb", "DrawProb", "LossProb")
            info2_names <- c("AWinOdds", "DrawOdds", "BWinOdds")
            my_out_name <- out_name[5]
            for (info_name in info_names) {
                local({
                    my_info_name <- info_name
                    end_out_name <- paste(my_out_name, my_info_name, sep = "")

                    index <- which(info_names == my_info_name)
                    output[[end_out_name]] <<- renderText({
                        prob <- get(out_name[6])()[index]
                        if (!is.na(prob)) {
                            format(prob, digits=3, nsmall=3)
                        }
                    })

                    my_info2_name <- info2_names[index]
                    end_out_name <- paste(my_out_name, my_info2_name, sep = "")

                    output[[end_out_name]] <<- renderText({
                        prob <- get(out_name[6])()[index]
                        if (!is.na(prob)) {
                            format(100 / (prob * 100), digits=3, nsmall=3)
                        }
                    })
                })
            }

            end_out_name <- paste(my_out_name, "SideProb", sep = "")
            out_name_stats <- paste(my_out_name, "Stats", sep = "")
            output[[end_out_name]] <<- renderPrint({
                weakerPlayer <- get(out_name_stats)()[4]
                if (weakerPlayer != 0) {
                    if (weakerPlayer == 1) {
                        cat("Probs. and odds for white player (w/d/l)")
                    } else {
                        cat("Probs. and odds for black player (w/d/l)")
                    }
                } else {
                    cat("")
                }
            })
        })
    })

    output$teamAWinProb <- renderText({
        format(teamProbs()[1], digits=3, nsmall=3)
    })
    output$teamADrawProb <- renderText({
        format(teamProbs()[2], digits=3, nsmall=3)
    })
    output$teamALossProb <- renderText({
        format(1 - teamProbs()[1] - teamProbs()[2], digits=3, nsmall=3)
    })

    output$teamAWinOdds <- renderText({
        format(100 / (teamProbs()[1] * 100), digits=3, nsmall=2)
    })
    output$teamDrawOdds <- renderText({
        format(100 / (teamProbs()[2] * 100), digits=3, nsmall=2)
    })
    output$teamBWinOdds <- renderText({
        format(100 / ((1 - teamProbs()[1] - teamProbs()[2]) * 100),
            digits=3, nsmall=2)
    })

})

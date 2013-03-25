# http://en.chessbase.com/Home/TabId/211/PostId/4009158/team-events-beating-the-bookmakers-150313.aspx

library(shiny)

library(XML)
library(gtools)

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

getPlayerProfile <- function(player) {
    fideRatingsUrl <- "http://ratings.fide.com/search.phtml?search="

    playerUrl <- paste(fideRatingsUrl, "'", player, "'", sep="")
    tables <- readHTMLTable(playerUrl)

    table <- tables[[1]]
    card <- getIntegerfromFactor(table[6, 1])
    player <- as.character(table[6, 2])
    rating <- getIntegerfromFactor(table[6, 7])

    profile <- list(
      card=card,
      player=player,
      rating=rating
    )

    profile
}

getPlayersStats <- function(card1, card2) {
    fideCardStatsUrl <- "http://ratings.fide.com/chess_statistics.phtml?event="

    playersRating <- c(card1$rating, card2$rating)
    weakerPlayerColumn <- match(min(playersRating), playersRating)

    playersCards <- c(card1$card, card2$card)
    playerCard <- playersCards[weakerPlayerColumn]

    statsUrl <- paste(fideCardStatsUrl, playerCard, sep="")
    doc <- htmlParse(statsUrl)
    tableNodes = getNodeSet(doc, "//table")

    table <- readHTMLTable(tableNodes[[6]])
    whiteWin <- getIntegerfromFactor(table[2, ])
    whiteDraw <- getIntegerfromFactor(table[3, ])
    whiteLoss <- getIntegerfromFactor(table[4, ])

    table <- readHTMLTable(tableNodes[[7]])
    blackWin <- getIntegerfromFactor(table[2, ])
    blackDraw <- getIntegerfromFactor(table[3, ])
    blackLoss <- getIntegerfromFactor(table[4, ])

    whiteTotal <- whiteWin + whiteDraw + whiteLoss
    blackTotal <- blackWin + blackDraw + blackLoss

    whiteWinPerc <- whiteWin / whiteTotal
    whiteDrawPerc <- whiteDraw / whiteTotal
    blackWinPerc <- blackWin / blackTotal
    blackDrawPerc <- blackDraw / blackTotal


    if (weakerPlayerColumn == 1) {
        score <- EloExpectedScore(playersRating[1], playersRating[2])
    } else {
        score <- EloExpectedScore(playersRating[2], playersRating[1])
    }

    whiteProbs <- getProb(score, whiteWinPerc, whiteDrawPerc)
    blackProbs <- getProb(score, blackWinPerc, blackDrawPerc)

    probs <- if (weakerPlayerColumn == 1) whiteProbs else blackProbs

    c(probs, weakerPlayerColumn)
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
        getPlayerProfile(input$playerA1)
    })
    game1PlayerBProfile <- reactive ({
        getPlayerProfile(input$playerB1)
    })
    game1Stats <- reactive({
        getPlayersStats(game1PlayerAProfile(), game1PlayerBProfile())
    })

    game2PlayerAProfile <- reactive ({
        getPlayerProfile(input$playerA2)
    })
    game2PlayerBProfile <- reactive ({
        getPlayerProfile(input$playerB2)
    })
    game2Stats <- reactive({
        getPlayersStats(game2PlayerAProfile(), game2PlayerBProfile())
    })

    game3PlayerAProfile <- reactive ({
        getPlayerProfile(input$playerA3)
    })
    game3PlayerBProfile <- reactive ({
        getPlayerProfile(input$playerB3)
    })
    game3Stats <- reactive({
        getPlayersStats(game3PlayerAProfile(), game3PlayerBProfile())
    })

    game4PlayerAProfile <- reactive ({
        getPlayerProfile(input$playerA4)
    })
    game4PlayerBProfile <- reactive ({
        getPlayerProfile(input$playerB4)
    })
    game4Stats <- reactive({
        getPlayersStats(game4PlayerAProfile(), game4PlayerBProfile())
    })

    teamProbs <- reactive({
        gamesProbs <- c()

        gamesProbs <- rbind(gamesProbs, game1Stats())
        gamesProbs <- rbind(gamesProbs, game2Stats())
        gamesProbs <- rbind(gamesProbs, game3Stats())
        gamesProbs <- rbind(gamesProbs, game4Stats())

        getTeamProbs(gamesProbs)
    })

    output_names <- c(
        "profileA1",
        "profileB1",
        "profileA2",
        "profileB2",
        "profileA3",
        "profileB3",
        "profileA4",
        "profileB4"
    )
    reactive_names <- c(
        "game1PlayerAProfile",
        "game1PlayerBProfile",
        "game2PlayerAProfile",
        "game2PlayerBProfile",
        "game3PlayerAProfile",
        "game3PlayerBProfile",
        "game4PlayerAProfile",
        "game4PlayerBProfile"
    )

    for (out_name in output_names) {
        local({
            my_out_name <- out_name
            info_names <- c("Card", "Player", "Rating")
            for (info_name in info_names) {
                local({
                    my_info_name <- info_name
                    complete_out_name <- paste(my_out_name, my_info_name,
                                            sep = "")

                    output[[complete_out_name]] <<- renderText({
                        my_profile <- get(reactive_names[
                            which(output_names == my_out_name)])()
                        my_profile[[tolower(my_info_name)]]
                    })
                })
            }
        })
    }

    output_games <- c(
        "game1",
        "game2",
        "game3",
        "game4"
    )
    reactive_stats <- c(
        "game1Stats",
        "game2Stats",
        "game3Stats",
        "game4Stats"
    )

    for (out_name in output_games) {
        local({
            my_out_name <- out_name
            info_names <- c("WinProb", "DrawProb", "LossProb")
            for (info_name in info_names) {
                local({
                    my_info_name <- info_name
                    complete_out_name <- paste(my_out_name, my_info_name,
                                            sep = "")

                    output[[complete_out_name]] <<- renderText({
                        my_probs <- get(reactive_stats[
                            which(output_games == my_out_name)])()
                        format(my_probs[which(info_names == my_info_name)],
                            digits=3, nsmall=3)
                    })
                })
            }

            complete_out_name <- paste(my_out_name, "SideProb", sep = "")
            out_name_stats <- paste(my_out_name, "Stats", sep = "")
            output[[complete_out_name]] <<- renderPrint({
                if (get(out_name_stats)()[4] == 1) {
                    cat("Probs. for white player (w/d/l)")
                } else {
                    cat("Probs. for black player (w/d/l)")
                }
            })
        })
    }

# Team probs

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

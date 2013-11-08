library(shiny)

library(XML)
library(gtools)

options(stringsAsFactors = FALSE)

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

getPlayerProfile <- function(player) {
    fideRatingsUrl <- "http://ratings.fide.com/search.phtml?search="

    playerUrl <- paste(fideRatingsUrl, player, sep="")
    tables <- readHTMLTable(playerUrl)

    table <- tables[[1]]
    card <- as.numeric(gsub("([^0-9]+)", "", table[7, 1]))
    player <- gsub("(^ +)|( +$)", "", table[7, 2])
    rating <- as.numeric(gsub("([^0-9]+)", "", table[7, 7]))

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
    whiteWin <- as.numeric(gsub("([^0-9]+)", "", table[2, ]))
    whiteDraw <- as.numeric(gsub("([^0-9]+)", "", table[3, ]))
    whiteLoss <- as.numeric(gsub("([^0-9]+)", "", table[4, ]))

    table <- readHTMLTable(tableNodes[[7]])
    blackWin <- as.numeric(gsub("([^0-9]+)", "", table[2, ]))
    blackDraw <- as.numeric(gsub("([^0-9]+)", "", table[3, ]))
    blackLoss <- as.numeric(gsub("([^0-9]+)", "", table[4, ]))

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
            info_names <- c("Card", "Player", "Rating")
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
                        my_probs <- get(out_name[6])()
                        format(my_probs[index], digits=3, nsmall=3)
                    })

                    my_info2_name <- info2_names[index]
                    end_out_name <- paste(my_out_name, my_info2_name, sep = "")

                    output[[end_out_name]] <<- renderText({
                        format(100 / ( get(out_name[6])()[index] * 100),
                            digits=3, nsmall=3)
                    })
                })
            }

            end_out_name <- paste(my_out_name, "SideProb", sep = "")
            out_name_stats <- paste(my_out_name, "Stats", sep = "")
            output[[end_out_name]] <<- renderPrint({
                if (get(out_name_stats)()[4] == 1) {
                    cat("Probs. and odds for white player (w/d/l)")
                } else {
                    cat("Probs. and odds for black player (w/d/l)")
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

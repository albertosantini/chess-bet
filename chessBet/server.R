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
    lost <- 1 - win - draw

    c(win, draw, lost)
}

printProfile <- function(card) {
    cat("Card number:", card$card)
    cat("\n")
    cat("Player:", card$player)
    cat("\n")
    cat("Rating:", card$rating)
}

printStats <- function(probs) {
    cat("Win :", format(probs[1], nsmall=2))
    cat("\n")
    cat("Draw:", format(probs[2], nsmall=2))
    cat("\n")
    cat("Lost:", format(probs[3], nsmall=2))
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
    whiteLost <- getIntegerfromFactor(table[4, ])

    table <- readHTMLTable(tableNodes[[7]])
    blackWin <- getIntegerfromFactor(table[2, ])
    blackDraw <- getIntegerfromFactor(table[3, ])
    blackLost <- getIntegerfromFactor(table[4, ])

    whiteTotal <- whiteWin + whiteDraw + whiteLost
    blackTotal <- blackWin + blackDraw + blackLost

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

    probs
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

    teamWinProb = sum(apply(teamWins, 1, function(outcomes) {
        gamesProbs[1, outcomes[1]] *
        gamesProbs[2, outcomes[2]] *
        gamesProbs[3, outcomes[3]] *
        gamesProbs[4, outcomes[4]]
    }))

    teamDrawProb = sum(apply(teamDraws, 1, function(outcomes) {
        gamesProbs[1, outcomes[1]] *
        gamesProbs[2, outcomes[2]] *
        gamesProbs[3, outcomes[3]] *
        gamesProbs[4, outcomes[4]]
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

    output$playerA1Profile <- renderPrint({
        printProfile(game1PlayerAProfile())
    })
    output$playerB1Profile <- renderPrint({
        printProfile(game1PlayerBProfile())
    })
    output$game1Stats <- renderPrint({
        printStats(game1Stats())
    })

    output$playerA2Profile <- renderPrint({
        printProfile(game2PlayerAProfile())
    })
    output$playerB2Profile <- renderPrint({
        printProfile(game2PlayerBProfile())
    })
    output$game2Stats <- renderPrint({
        printStats(game2Stats())
    })

    output$playerA3Profile <- renderPrint({
        printProfile(game3PlayerAProfile())
    })
    output$playerB3Profile <- renderPrint({
        printProfile(game3PlayerBProfile())
    })
    output$game3Stats <- renderPrint({
        printStats(game3Stats())
    })

    output$playerA4Profile <- renderPrint({
        printProfile(game4PlayerAProfile())
    })
    output$playerB4Profile <- renderPrint({
        printProfile(game4PlayerBProfile())
    })
    output$game4Stats <- renderPrint({
        printStats(game4Stats())
    })

    output$teamProbs <- renderPrint({
        gamesProbs <- c()

        gamesProbs <- rbind(gamesProbs, game1Stats())
        gamesProbs <- rbind(gamesProbs, game2Stats())
        gamesProbs <- rbind(gamesProbs, game3Stats())
        gamesProbs <- rbind(gamesProbs, game4Stats())

        teamProbs <- getTeamProbs(gamesProbs)

        cat(
            "Win Prob. for team A", teamProbs[1], "/",
            "Draw Prob. for team A", teamProbs[2], "/",
            "Lost Prob. for team A", 1 - teamProbs[1] - teamProbs[2]
        )
        cat("\n")
        cat(
            "Win Odds for team A", 100 / (teamProbs[1] * 100), "/",
            "Draw Odds", 100 / (teamProbs[2] * 100), "/",
            "Win Odds for team B", 100 / ((1 - teamProbs[1] - teamProbs[2]) * 100)
        )
    })
})

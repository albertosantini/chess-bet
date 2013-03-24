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

# Game 1

    output$profileA1Card <- renderText({
        game1PlayerAProfile()$card
    })
    output$profileA1Player <- renderText({
        game1PlayerAProfile()$player
    })
    output$profileA1Rating <- renderText({
        game1PlayerAProfile()$rating
    })

    output$profileB1Card <- renderText({
        game1PlayerBProfile()$card
    })
    output$profileB1Player <- renderText({
        game1PlayerBProfile()$player
    })
    output$profileB1Rating <- renderText({
        game1PlayerBProfile()$rating
    })

    output$game1SideProb <- renderPrint({
        if (game1Stats()[4] == 1) {
            cat("Probs. for white player (w/d/l)")
        } else {
            cat("Probs. for black player (w/d/l)")
        }
    })
    output$game1WinProb <- renderText({
        format(game1Stats()[1], digits=3, nsmall=3)
    })
    output$game1DrawProb <- renderText({
        format(game1Stats()[2], digits=3, nsmall=3)
    })
    output$game1LossProb <- renderText({
        format(game1Stats()[3], digits=3, nsmall=3)
    })

# Game 2

    output$profileA2Card <- renderText({
        game2PlayerAProfile()$card
    })
    output$profileA2Player <- renderText({
        game2PlayerAProfile()$player
    })
    output$profileA2Rating <- renderText({
        game2PlayerAProfile()$rating
    })

    output$profileB2Card <- renderText({
        game2PlayerBProfile()$card
    })
    output$profileB2Player <- renderText({
        game2PlayerBProfile()$player
    })
    output$profileB2Rating <- renderText({
        game2PlayerBProfile()$rating
    })

    output$game2SideProb <- renderPrint({
        if (game2Stats()[4] == 1) {
            cat("Probs. for white player (w/d/l)")
        } else {
            cat("Probs. for black player (w/d/l)")
        }
    })
    output$game2WinProb <- renderText({
        format(game2Stats()[1], digits=3, nsmall=3)
    })
    output$game2DrawProb <- renderText({
        format(game2Stats()[2], digits=3, nsmall=3)
    })
    output$game2LossProb <- renderText({
        format(game2Stats()[3], digits=3, nsmall=3)
    })

# Game 3

    output$profileA3Card <- renderText({
        game3PlayerAProfile()$card
    })
    output$profileA3Player <- renderText({
        game3PlayerAProfile()$player
    })
    output$profileA3Rating <- renderText({
        game3PlayerAProfile()$rating
    })

    output$profileB3Card <- renderText({
        game3PlayerBProfile()$card
    })
    output$profileB3Player <- renderText({
        game3PlayerBProfile()$player
    })
    output$profileB3Rating <- renderText({
        game3PlayerBProfile()$rating
    })

    output$game3SideProb <- renderPrint({
        if (game3Stats()[4] == 1) {
            cat("Probs. for white player (w/d/l)")
        } else {
            cat("Probs. for black player (w/d/l)")
        }
    })
    output$game3WinProb <- renderText({
        format(game3Stats()[1], digits=3, nsmall=3)
    })
    output$game3DrawProb <- renderText({
        format(game3Stats()[2], digits=3, nsmall=3)
    })
    output$game3LossProb <- renderText({
        format(game3Stats()[3], digits=3, nsmall=3)
    })

# Game 4

    output$profileA4Card <- renderText({
        game4PlayerAProfile()$card
    })
    output$profileA4Player <- renderText({
        game4PlayerAProfile()$player
    })
    output$profileA4Rating <- renderText({
        game4PlayerAProfile()$rating
    })

    output$profileB4Card <- renderText({
        game4PlayerBProfile()$card
    })
    output$profileB4Player <- renderText({
        game4PlayerBProfile()$player
    })
    output$profileB4Rating <- renderText({
        game4PlayerBProfile()$rating
    })

    output$game4SideProb <- renderPrint({
        if (game4Stats()[4] == 1) {
            cat("Probs. for white player (w/d/l)")
        } else {
            cat("Probs. for black player (w/d/l)")
        }
    })
    output$game4WinProb <- renderText({
        format(game4Stats()[1], digits=3, nsmall=3)
    })
    output$game4DrawProb <- renderText({
        format(game4Stats()[2], digits=3, nsmall=3)
    })
    output$game4LossProb <- renderText({
        format(game4Stats()[3], digits=3, nsmall=3)
    })

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

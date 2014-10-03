/* global jQuery, _ */

(function ($, _) {
    "use strict";

    var gameRawTemplate = $("#profiles-and-game-probs").text(),
        gameTemplate = _.template(gameRawTemplate),
        $game1 = $("#game1"),
        $game2 = $("#game2"),
        $game3 = $("#game3"),
        $game4 = $("#game4");

    $game1.html(gameTemplate({
        playerA: "playerA1",
        playerAValue: "Foisor Cristina Adela",
        profileACard: "profileA1Card",
        profileAPlayer: "profileA1Player",
        profileARating: "profileA1Rating",
        playerB: "playerB1",
        playerBValue: "Gunina Valentina",
        profileBCard: "profileB1Card",
        profileBPlayer: "profileB1Player",
        profileBRating: "profileB1Rating",
        gameSideProb: "game1SideProb",
        gameWinProb: "game1WinProb",
        gameDrawProb: "game1DrawProb",
        gameLossProb: "game1LossProb",
        gameAWinOdds: "game1AWinOdds",
        gameDrawOdds: "game1DrawOdds",
        gameBWinOdds: "game1BWinOdds"
    }));

    $game2.html(gameTemplate({
        playerA: "playerA2",
        playerAValue: "Bulmaga Irina",
        profileACard: "profileA2Card",
        profileAPlayer: "profileA2Player",
        profileARating: "profileA2Rating",
        playerB: "playerB2",
        playerBValue: "Kosteniuk Alexandra",
        profileBCard: "profileB2Card",
        profileBPlayer: "profileB2Player",
        profileBRating: "profileB2Rating",
        gameSideProb: "game2SideProb",
        gameWinProb: "game2WinProb",
        gameDrawProb: "game2DrawProb",
        gameLossProb: "game2LossProb",
        gameAWinOdds: "game2AWinOdds",
        gameDrawOdds: "game2DrawOdds",
        gameBWinOdds: "game2BWinOdds"
    }));

    $game3.html(gameTemplate({
        playerA: "playerA3",
        playerAValue: "L'Ami Alina",
        profileACard: "profileA3Card",
        profileAPlayer: "profileA3Player",
        profileARating: "profileA3Rating",
        playerB: "playerB3",
        playerBValue: "Galliamova Alisa",
        profileBCard: "profileB3Card",
        profileBPlayer: "profileB3Player",
        profileBRating: "profileB3Rating",
        gameSideProb: "game3SideProb",
        gameWinProb: "game3WinProb",
        gameDrawProb: "game3DrawProb",
        gameLossProb: "game3LossProb",
        gameAWinOdds: "game3AWinOdds",
        gameDrawOdds: "game3DrawOdds",
        gameBWinOdds: "game3BWinOdds"
    }));

    $game4.html(gameTemplate({
        playerA: "playerA4",
        playerAValue: "Voicu-Jagodzinsky Carmen",
        profileACard: "profileA4Card",
        profileAPlayer: "profileA4Player",
        profileARating: "profileA4Rating",
        playerB: "playerB4",
        playerBValue: "Girya Olga",
        profileBCard: "profileB4Card",
        profileBPlayer: "profileB4Player",
        profileBRating: "profileB4Rating",
        gameSideProb: "game4SideProb",
        gameWinProb: "game4WinProb",
        gameDrawProb: "game4DrawProb",
        gameLossProb: "game4LossProb",
        gameAWinOdds: "game4AWinOdds",
        gameDrawOdds: "game4DrawOdds",
        gameBWinOdds: "game4BWinOdds"
    }));

}(jQuery, _));

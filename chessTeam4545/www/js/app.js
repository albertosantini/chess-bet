/* global jQuery, _, depot */

(function ($, _, depot) {
    'use strict';

    var gamesStore = depot('games'),
        gameRawTemplate = $('#profiles-and-game-probs').text(),
        gameTemplate = _.template(gameRawTemplate),
        game1 = {
            gameId: 1,
            playerA: 'playerA1',
            playerAValue: 'RedAttack',
            profileAPlayer: 'profileA1Player',
            profileARating: 'profileA1Rating',
            playerB: 'playerB1',
            playerBValue: 'chess9793',
            profileBPlayer: 'profileB1Player',
            profileBRating: 'profileB1Rating',
            gameSideProb: 'game1SideProb',
            gameWinProb: 'game1WinProb',
            gameDrawProb: 'game1DrawProb',
            gameLossProb: 'game1LossProb',
            gameAWinOdds: 'game1AWinOdds',
            gameDrawOdds: 'game1DrawOdds',
            gameBWinOdds: 'game1BWinOdds'
        },
        $game1 = $('#game1'),
        game2 = {
            gameId: 2,
            playerA: 'playerA2',
            playerAValue: 'IceBox',
            profileAPlayer: 'profileA2Player',
            profileARating: 'profileA2Rating',
            playerB: 'playerB2',
            playerBValue: 'ben622',
            profileBPlayer: 'profileB2Player',
            profileBRating: 'profileB2Rating',
            gameSideProb: 'game2SideProb',
            gameWinProb: 'game2WinProb',
            gameDrawProb: 'game2DrawProb',
            gameLossProb: 'game2LossProb',
            gameAWinOdds: 'game2AWinOdds',
            gameDrawOdds: 'game2DrawOdds',
            gameBWinOdds: 'game2BWinOdds'
        },
        $game2 = $('#game2'),
        game3 = {
            gameId: 3,
            playerA: 'playerA3',
            playerAValue: 'frank001',
            profileAPlayer: 'profileA3Player',
            profileARating: 'profileA3Rating',
            playerB: 'playerB3',
            playerBValue: 'stile',
            profileBPlayer: 'profileB3Player',
            profileBRating: 'profileB3Rating',
            gameSideProb: 'game3SideProb',
            gameWinProb: 'game3WinProb',
            gameDrawProb: 'game3DrawProb',
            gameLossProb: 'game3LossProb',
            gameAWinOdds: 'game3AWinOdds',
            gameDrawOdds: 'game3DrawOdds',
            gameBWinOdds: 'game3BWinOdds'
        },
        $game3 = $('#game3'),
        game4 = {
            gameId: 4,
            playerA: 'playerA4',
            playerAValue: 'FlyingTiger',
            profileAPlayer: 'profileA4Player',
            profileARating: 'profileA4Rating',
            playerB: 'playerB4',
            playerBValue: 'leland',
            profileBPlayer: 'profileB4Player',
            profileBRating: 'profileB4Rating',
            gameSideProb: 'game4SideProb',
            gameWinProb: 'game4WinProb',
            gameDrawProb: 'game4DrawProb',
            gameLossProb: 'game4LossProb',
            gameAWinOdds: 'game4AWinOdds',
            gameDrawOdds: 'game4DrawOdds',
            gameBWinOdds: 'game4BWinOdds'
        },
        $game4 = $('#game4'),
        game;

    game = gamesStore.find({gameId: 1});
    if (game.length === 1) {
        game1 = game[0];
    }
    game = gamesStore.find({gameId: 2});
    if (game.length === 1) {
        game2 = game[0];
    }
    game = gamesStore.find({gameId: 3});
    if (game.length === 1) {
        game3 = game[0];
    }
    game = gamesStore.find({gameId: 4});
    if (game.length === 1) {
        game4 = game[0];
    }

    $game1.html(gameTemplate(game1));
    $game2.html(gameTemplate(game2));
    $game3.html(gameTemplate(game3));
    $game4.html(gameTemplate(game4));

    if (gamesStore.all().length === 0) {
        gamesStore.save(game1);
        gamesStore.save(game2);
        gamesStore.save(game3);
        gamesStore.save(game4);
    }

    $('input[type="text"]').change(function (e) {
        var id = $(e.target).parent().parent().parent().attr('id'),
            playerLabel = e.target.name,
            playerValue = $(this).val(),
            game;

        game = gamesStore.find({gameId: parseInt(id, 10)});
        if (playerLabel.search("playerA") >= 0) {
            game[0].playerAValue = playerValue;
        }
        if (playerLabel.search("playerB") >= 0) {
            game[0].playerBValue = playerValue;
        }
        gamesStore.update(game[0]._id, game[0]);
    });

}(jQuery, _, depot));


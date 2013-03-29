CHESS-BET
=========

Based on the post [Team events: beating the bookmakers?!](http://en.chessbase.com/Home/TabId/211/PostId/4009158/team-events-beating-the-bookmakers-150313.aspx)
the app implements the steps described to calculate chess team odds.

The project contains two implementations:

- *chessBet*, implementing the approach described in the post applied to FIDE
ratings.

- *chessTeam4545*, implementing the approach described in the post applied to
the [Team 4545 League](http://team4545league.org/).

Installation
============

To use locally the app, you need to install [R](http://www.r-project.org/) with
the package [Shiny](http://www.rstudio.com/shiny/).

After cloning the project, with the working directory set to project folder,
type in R console:

    require(shiny)

    runApp("chessBet")

or

    runApp("chessTeam4545")


Todo
====

- Add validation for the input fields to allow blank games.

- Add rating and stats games inputs to insert players not in FIDE database.

- Save the latest players typed in the local storage.

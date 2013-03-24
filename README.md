chess-bet
=========

Based on the post [Team events: beating the bookmakers?!](http://en.chessbase.com/Home/TabId/211/PostId/4009158/team-events-beating-the-bookmakers-150313.aspx)
the app implements the steps described to calculate chess team odds.

Installation
============

To use locally the app, you need to install [R](http://www.r-project.org/) with
the package [Shiny](http://www.rstudio.com/shiny/).

Then, with the working directory set to project folder, type in R console:

    require(shiny)

    runApp("chessBet")

Todo
====

- Add validation for the input fields to allow blank games.

- Add rating and stats games inputs to insert players not in FIDE database.

- Save the latest players typed in the local storage.

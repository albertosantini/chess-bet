CHESS-BET
=========

Based on the post [Team events: beating the bookmakers?!][1] the app implements
the steps described to calculate chess team odds.

The project contains two implementations:

- *chessBet*, implementing the approach described in the post applied to FIDE
ratings.

- *chessTeam4545*, implementing the approach described in the post applied to
the [Team 4545 League][2].

Installation
============

To use locally the app, you need to install [R][3] with the package [Shiny][4].

After cloning the project, with the working directory set to project folder,
type the following commands in R console.

Install the dependencies

    install.packages(c("shiny", "XML", "gtools"))

Then start the app chessBet

    require(shiny)
    runApp("chessBet")

or the app chessTeam4545

    require(shiny)
    runApp("chessTeam4545")


Live
====

- http://glimmer.rstudio.com/icebox/chessBet/

- http://glimmer.rstudio.com/icebox/chessTeam4545/

Todo
====

- Add validation for the input fields to allow blank games.

- Add rating and stats games inputs to insert players not in FIDE database.

- Save the latest players typed in the local storage.

[1]: http://goo.gl/QN3oQ
[2]: http://team4545league.org/
[3]: http://www.r-project.org/
[4]: http://www.rstudio.com/shiny/

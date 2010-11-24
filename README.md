Flash Duel
==========

[Flash Duel][1] is a pretty simple board game. This is a Ruby implementation of
the rules in the game so you can write bots to play it.

The goal of this project is to allow lazy people like me to empirically figure
out the best approach for this game. It's also a reminder of what one can do by
skipping Starcraft for a night or two.


Game Rules
----------

Refer to this [pdf with the game instructions][2].


Bot API
-------

Your bot can be defined in any class. It must respond to two methods:

    def play(hand, board)

    def respond(action, attack, hand, board)

* `hand` is your current hand, represented in an Array. eg: `[1, 3, 3, 2, 5]`

* `board` is a wrapper to game board with some conveniency methods:
  
  `board.distance` is the distance between the two players.
  `board.on_edge?(self)` tells you whether you're on the edge of it.

* `attack` is the attacking hand, represented in an Array. eg: `[3, 3]`

* `action` is a symbol representing what the oponent used to hit you.
  Options are `:attack` or `:strike`.

For each of these methods, you need to respond with an array containing
an action, and one or more cards.

Valid actions:
* `[:move, 5]`
* `[:push, 3]`
* `[:attack, [4, 4]]`
* `[:strike, [3, 4]]`

Valid responses:
* `[:retreat, 1]`
* `[:block, [4, 4]]`


Playing games
-------------

Use the flash-duel binary:

    flash-duel bots/random.rb bots/mine.rb


TODO
----

* Change the API to run bots as new processes, allowing more languages and 
  avoiding simple hacks/security wholes.

* Implement characters and their special abilities.

* Support more command line options: running multiple games, defining who's
  the first player, print a summary, etc.

* Enhance the web api / provide some sort of tournament.


Reference
---------

[1]: http://www.sirlingames.com/collections/flash-duel "Flash Duel"
[2]: http://www.sirlin.net/fd/rules                    "Flash Duel Rules (PDF)"


About
-----

Written by Pedro Belo.

Licensed as GPLv2 - once this gets to be the next eSport I'll want my share.

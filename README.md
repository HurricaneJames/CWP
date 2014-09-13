Chess with Possibilities
==

This is an implementation of the Chess with Possibilities game.

Mostly I'm just playing around at this point. I consider this some of the worst code I've written in a while, much of it intentionally so.

TODO
==
  - [ ] draw mechanism
    - [ ] can only offer once per move
    - [ ] front end has a way to automatically refuse draws
  - [ ] develop pawn promotion
    - [ ] move: '5,6:5,7:[anykill]:[name]'
    - [ ] where name => [rook, knight, bishop, queen, etc...]
    - [ ] may need to redevelop the rules to add a promotion set to rules that allow promotion
  - [ ] develop a point-and-click interface to make debugging easier (note: not the final version of the interface)
    - [ ] it should have move prediection
      - [ ] click on a square and it shows all valid moves and the probability of moving there
      - [ ] probably via colored tiles (green = strong => red = weak)
      - [ ] gold colored tile = 100% chance
      - [ ] bio-hazard sign = 0% chance
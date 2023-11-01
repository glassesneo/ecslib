discard """
  action: "run"
"""

import
  ../src/ecslib

type
  Position = object
    x, y: int

  Velocity = object
    x, y: int

  HP = object
    max, current: int

  MP = object
    max, current: int

  PlayerStatus = tuple
    hp: HP
    mp: MP

proc new(_: type PlayerStatus, hp: HP, mp: MP): PlayerStatus =
  result = (
    hp: hp,
    mp: mp
  )

let world = World.new()

let entity {.used.} = world.create()
  .withBundle((
  Position(x: 5, y: 5),
  Velocity(x: 0, y: 0)
  ))
  .withBundle(PlayerStatus.new(
    hp = HP(max: 200),
    mp = MP(max: 80)
  ))

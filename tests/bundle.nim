discard """
  action: "run"
"""

import
  ../src/ecslib

type
  Position = ref object
    x, y: int

  Velocity = ref object
    x, y: int

  HP = ref object
    max, current: int

  MP = ref object
    max, current: int

let world = World.new()

proc withPlayerBundle(entity: Entity, hp: HP, mp: MP): Entity =
  return entity.withBundle((hp, mp))

let entity {.used.} = world.create()
  .withBundle((
    Position(x: 5, y: 5),
    Velocity(x: 0, y: 0)
  ))
  .withPlayerBundle(
    hp = HP(max: 200),
    mp = MP(max: 80)
  )

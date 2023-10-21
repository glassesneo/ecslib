discard """
  action: "run"
"""

import
  std/unittest,
  ../src/ecslib

type
  Position = ref object
    x, y: int

  Velocity = ref object
    x, y: int

let world = World.new()

let
  entity = world.create()

entity
  .attach(
    Position(x: 0, y: 15)
  ).attach(
    Velocity(x: 5, y: 0)
  )

check entity.hasAll("Position", "Velocity")

entity.detach(Velocity)

check entity.has("Position")

check not entity.has(Velocity)

check entity.hasAny("Position", "Velocity")

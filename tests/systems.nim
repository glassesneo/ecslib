discard """
  action: "run"
"""

import
  ../src/ecslib,
  std/macros,
  std/unittest

type
  Position = object
    x, y: int

  Velocity = object
    x, y: int

let world = World.new()

let
  entity1 = world.create()
  entity2 = world.create()

entity1
  .attach(
    Position(x: 0, y: 0)
  ).attach(
    Velocity(x: 5, y: 0)
  )

entity2
  .attach(
    Position(x: 0, y: 0)
  ).attach(
    Velocity(x: 0, y: 5)
  )

proc updatePosition(all = [var Position, Velocity]) {.system.} =
  for pos, vel in each(var Position, Velocity):
    pos.x += vel.x
    pos.y += vel.y


proc emptySystem() {.system.} =
  discard

world.addSystem(updatePosition)
world.addSystem(emptySystem)

check entity1[Position].x == 0
check entity2[Position].y == 0

for i in 0..<10:
  world.runSystems()

check entity1[Position].x == 50
check entity2[Position].y == 50

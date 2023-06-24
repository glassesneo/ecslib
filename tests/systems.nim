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

let world = World.new()

let
  entity1 = world.create()
  entity2 = world.create()

entity1
  .attach(
    Position(x: 0, y: 15)
  ).attach(
    Velocity(x: 5, y: 0)
  )

entity2
  .attach(
    Position(x: 5, y: 15)
  ).attach(
    Velocity(x: 5, y: 0)
  )

proc updatePosition(vel: Velocity[with(Position)], pos: Position) {.system.} =
  for c1 in pos:
    for c2 in vel:
      c1.x += c2.x

echo entity1[Position].x
echo entity2[Position].x
echo "==================="

world.runSystem(updatePosition)

echo entity1[Position].x
echo entity2[Position].x
echo "==================="

discard """
  action: "run"
"""

import
  ../src/ecslib,
  std/macros

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

proc updatePosition(query: [All(Velocity, Position)]) {.system.} =
  for pos, vel in each(Position, Velocity):
    pos.x += vel.x
    pos.y += vel.y

world.addSystem(updatePosition)

echo "entity1 pos.x: ", entity1[Position].x
echo "entity2 pos.y: ", entity2[Position].y
echo "==================="

world.runSystems()

echo "entity1 pos.x: ", entity1[Position].x
echo "entity2 pos.y: ", entity2[Position].y
echo "==================="

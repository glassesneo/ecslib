discard """
  action: "run"
"""

import
  ../src/ecslib {.all.}

type
  Position = ref object
    x, y: int

  Velocity = ref object
    x, y: int

  A = ref object
  B = ref object
  C = ref object

let world = World.new()

let
  entity1 = world.create()
  entity2 = world.create()
  entity3 = world.create()

entity1
  .attach(
    Position(x: 0, y: 0)
  ).attach(
    Velocity(x: 5, y: 0)
  ).attach(A())

entity2
  .attach(
    Position(x: 0, y: 0)
  ).attach(
    Velocity(x: 0, y: 5)
  ).attach(B())

entity3
  .attach(
    Position(x: 0, y: 0)
  ).attach(
    Velocity(x: 0, y: 5)
  ).attach(C())



proc moveSystem(world: World) {.system.} =
  defineQuery(world):
    ballQuery:
      All = @[Position, Velocity]
      Any = @[A, C]
  ballQuery.iterate (pos, vel) in (Position, Velocity):
    pos.x += vel.x
    pos.y += vel.y
    echo "x: " & $pos.x
    echo "y: " & $pos.y

world.registerSystem(moveSystem)

for i in 1..10:
  world.runSystems()


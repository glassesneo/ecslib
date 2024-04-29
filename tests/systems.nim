discard """
  action: "run"
"""

import
  std/sets
import ../src/ecslib {.all.}

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

let ballQuery = world.createQuery(
  ["Position", "Velocity"].toHashSet(),
  qAny = ["A", "C"].toHashSet(),
)

proc moveSystem(ball: Query) =
  ball.iterate (pos, vel) in (Position, Velocity):
    pos.x += vel.x
    pos.y += vel.y
    echo entity

for i in 1..10:
  moveSystem(ballQuery)


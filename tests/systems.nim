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

let world = World.new()

let
  ball = world.create()

ball
  .attach(
    Position(x: 0, y: 0)
  ).attach(
    Velocity(x: 5, y: 2)
  )

proc moveSystem(All: [Position, Velocity]) {.system.} =
  for entity in entities:
    let pos = entity.get(Position)
    let vel = entity.get(Velocity)
    pos.x += vel.x
    pos.y += vel.y

proc showPositionSystem(All: [Position]) {.system.} =
  for entity in entities:
    let pos = entity.get(Position)
    echo "x: ", pos.x
    echo "y: ", pos.y

world.registerSystem(moveSystem)
world.registerSystem(showPositionSystem)

for i in 0..<10:
  world.runSystems()

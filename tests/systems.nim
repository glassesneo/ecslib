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

  Name = ref object
    name: string

let world = World.new()

let
  ball1 = world.create()
  ball2 = world.create()

ball1
  .attach(
    Position(x: 0, y: 0)
  ).attach(
    Velocity(x: 5, y: 2)
  ).attach(
    A()
  ).attach(
    Name(name: "ball1")
  )

ball2
  .attach(
    Position(x: 10, y: 100)
  ).attach(
    Velocity(x: 5, y: -5)
  ).attach(
    B()
  ).attach(
    Name(name: "ball2")
  )

proc moveSystem(All: [Position, Velocity]) {.system.} =
  for entity in entities:
    let pos = entity.get(Position)
    let vel = entity.get(Velocity)
    pos.x += vel.x
    pos.y += vel.y

proc showPositionSystem(All: [Position, Name], Any: [A, B]) {.system.} =
  for entity in entities:
    let pos = entity.get(Position)
    let name = entity.get(Name).name
    echo "[", name, "]"
    echo "  x: ", pos.x
    echo "  y: ", pos.y

world.registerSystem(moveSystem)
world.registerSystem(showPositionSystem)

for i in 0..<10:
  world.runSystems()

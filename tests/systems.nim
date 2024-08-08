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

proc startup(All: [Name]) {.system.} =
  for name in each(entities, [Name]):
    echo name.name
  echo "=====Startup!====="

proc moveSystem(All: [Position, Velocity]) {.system.} =
  for pos, vel in each(entities, [Position, Velocity]):
    pos.x += vel.x
    pos.y += vel.y

proc showPositionSystem(
    All: [Position, Velocity, Name],
    Any: [A, B]
) {.system.} =
  for pos, name in each(entities, [Position, Name]):
    echo "[", name.name, "]"
    echo "  x: ", pos.x
    echo "  y: ", pos.y

proc doNothing*() {.system.} =
  discard

proc terminate {.system.} =
  echo "=====Terminate!====="

world.registerStartupSystems(startup)
world.registerSystems(moveSystem, showPositionSystem, doNothing)
world.registerTerminateSystems(terminate)

if isMainModule:
  world.runStartupSystems()
  for i in 0..<10:
    world.runSystems()
  world.runTerminateSystems()

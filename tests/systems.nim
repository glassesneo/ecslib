discard """
  action: "run"
"""

import
  macros,
  tables,
  ../src/ecslib

type
  Position = ref object
    x, y: int

  Velocity = ref object
    x, y: int

  A = ref object
  B = ref object
  C = ref object

  Name = ref object
    name: string

proc startup(entities: [All[Name]]) {.system.} =
  for name in each(entities, [Name]):
    echo name.name
  echo "=====Startup!====="

proc moveSystem(
    entities: [All[Position, Velocity], None[C]],
    entities2: [All[C]]
) {.system.} =
  for pos, vel in each(entities, [Position, Velocity]):
    pos.x += vel.x
    pos.y += vel.y

  echo entities2

proc showPositionSystem(
    entities: [All[Position, Velocity, Name], Any[A, B]]
) {.system.} =
  for pos, name in each(entities, [Position, Name]):
    echo "[", name.name, "]"
    echo "  x: ", pos.x
    echo "  y: ", pos.y

proc doNothing*() {.system.} =
  discard

proc terminate {.system.} =
  echo "=====Terminate!====="

let world = World.new()

let
  ball1 = world.create()
  ball2 = world.create()
  ball3 = world.create()

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

ball3
  .attach(
    Position(x: 0, y: 0)
  ).attach(
    Velocity(x: 0, y: 0)
  ).attach(
    C()
  )

world.registerStartupSystems(startup)
world.registerSystems(moveSystem, showPositionSystem, doNothing)
world.registerTerminateSystems(terminate)

if isMainModule:
  world.runStartupSystems()
  for i in 0..<10:
    world.runSystems()
  world.runTerminateSystems()


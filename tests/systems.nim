discard """
  action: "run"
"""

import
  typetraits,
  ../src/ecslib

type
  AppInfo = ref object
    appName: string

  Position = ref object
    x, y: int

  Velocity = ref object
    x, y: int

  A = ref object
    id: int
  B = ref object
    id: int
  C = ref object

  Name = ref object
    name: string

proc startup(
    entities: [All[Name]],
    appInfo: Resource[AppInfo]
) {.system.} =
  for name in each(entities, [Name]):
    echo name.name
  echo "=====Start ", appInfo.appName, "!====="

proc moveSystem(
    entities: [All[Position, Velocity], None[C]],
    entities2: [All[C]]
) {.system.} =
  for pos, vel in each(entities, [Position, Velocity]):
    pos.x += vel.x
    pos.y += vel.y

    for c in each(entities2, [C]):
      discard c
      echo "nested"

proc showPositionSystem(
    entities: [All[Position, Velocity, Name], Any[A, B]]
) {.system.} =
  for pos, name in each(entities, [Position, Name]):
    echo "[", name.name, "]"
    echo "  x: ", pos.x
    echo "  y: ", pos.y

proc namePairSystem(
    entities: [All[A, B]]
) {.system.} =
  entities.combination([a: A, b: B]):
    echo a.type.name, a.id, " & ", b.type.name, b.id

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

for i in 0..<10:
  world.create()
    .attach(A(id: i))
    .attach(B(id: i))

world.addResource(AppInfo(appName: "example"))
world.registerStartupSystems(startup)
world.registerSystems(moveSystem, showPositionSystem, doNothing)
world.registerTerminateSystems(terminate, namePairSystem)

if isMainModule:
  world.runStartupSystems()
  for i in 0..<10:
    world.runSystems()
  world.runTerminateSystems()


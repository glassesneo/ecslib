# Overview
## Easier and simpler game development with ECS
ecslib is a super cool and accomplished nimble package for Entity Component System.

## Example

### Create an ECS program
```nim
# Components ---- No need to register!
type
  Position = ref object
    x, y: int

  Velocity = ref object
    x, y: int

# Resources, global data for systems
  Time = ref object
    deltaTime: float

let world = World.new()

# Entity
let
  ball = world.create()

# Attaching components
ball
  .attach(
    Position(x: 0, y: 0)
  ).attach(
    Velocity(x: 5, y: 2)
  )

# You can define system using procedure syntax
proc moveSystem(
    # Querying targeted entities by `All`, `Any`, and `None` args
    entities: [All[Position, Velocity]],
    time: Resource[Time]
) {.system.} =
  # specifying resources that will be used in the system
  for pos, vel in each(entities, [Position, Velocity]):
    pos.x += vel.x * time.deltaTime
    pos.y += vel.y * time.deltaTime

proc showPositionSystem(entities: [All[Position]]) {.system.} =
  for pos in each(entities, [Position]):
    echo "x: ", pos.x
    echo "y: ", pos.y

# Add resources to world
world.addResource(Time(deltaTime: 30))

# Register systems to world
world.registerSystem(moveSystem)
world.registerSystem(showPositionSystem)

for i in 0..<10:
  world.runSystems()
```

## Installation
```nim
nimble install ecslib
```

# License
ecslib is licensed under the MIT license. See COPYING for details.


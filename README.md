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

# Register systems to world
world.registerSystem(moveSystem)
world.registerSystem(showPositionSystem)

for i in 0..<10:
  world.runSystems()
```

## Installation
```nim
nimble install https://github.com/glassesneo/ecslib
```

# License
ecslib is licensed under the MIT license. See COPYING for details.

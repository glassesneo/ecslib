# Overview
## Easier and simpler game development with ECS
ecslib is a super cool and accomplished nimble package for Entity Component System.

## Example

### Create an ECS program
```nim
import
  pkg/ecslib

# Components ---- no need to register!
type
  Position = ref object
    x, y: int

  Velocity = ref object
    x, y: int

# World
let world = World.new()

# Entities
let
  ball1 = world.create()
  ball2 = world.create()

# Attaching components to entities
ball1
  .attach(
    Position(x: 0, y: 0)
  ).attach(
    Velocity(x: 5, y: 0)
  )

ball2
  .attach(
    Position(x: 0, y: 0)
  ).attach(
    Velocity(x: 0, y: 5)
  )

# {.system.} pragma can generate a system
# from a procedure with the query of required components!
proc updatePosition(all = [Velocity, Position]) {.system.} =
  for pos, vel in each(Position, Velocity):
    # Iterate any number of different types by using `each` macro
    pos.x += vel.x
    pos.y += vel.y

proc showPosition(all = [Position]) {.system.} =
  for pos in each(Position):
    echo "x: ", pos.x
    echo "y: ", pos.y

# Add systems to `world`
world.addSystem(updatePosition)
world.addSystem(showPosition)

# Start the game!
for i in 0..<100:
  world.runSystems()
```

## Installation
```nim
nimble install ecslib
```

# License
ecslib is licensed under the MIT license. See COPYING for details.

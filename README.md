# Overview
## Easier and simpler game development with ECS
ecslib is a super cool and accomplished nimble package for Entity Component System.

## Example

### Create an ECS program
```nim

# Add systems to `world`
world.addSystem(updatePosition)
world.addSystem(showPosition)

for i in 0..<100:
  world.runSystems()



# Components ---- no need to register!
type
  Position = ref object
    x, y: int

  Velocity = ref object
    x, y: int

  A = ref object
  B = ref object
  C = ref object

let world = World.new()

# Entity
let
  entity1 = world.create()
  entity2 = world.create()
  entity3 = world.create()

# Attaching components to entities
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

# You can define queries anywhere
defineQuery(world):
  ballQuery:
    All = @[Position, Velocity]
    Any = @[A, C]

# {.system.} pragma can generate a system
# from a procedure with the query of required components
proc moveSystem(world: World) {.system.} =
  # Iterate any number of different types by using `iterate` macro
  ballQuery.iterate (pos, vel) in (Position, Velocity):
    pos.x += vel.x
    pos.y += vel.y

proc showPositionSystem(world: World) {.system.} =
  # You can also re-define queries as another name
  using ball = ballQuery
  ball.iterate (pos) in (Position):
    echo "x: " & $pos.x
    echo "y: " & $pos.y

# Register systems to `world`
world.registerSystem(moveSystem)
world.registerSystem(showPositionSystem)

# Start the game!
for i in 1..10:
  world.runSystems()
```

## Installation
```nim
nimble install https://github.com/glassesneo/ecslib
```

# License
ecslib is licensed under the MIT license. See COPYING for details.

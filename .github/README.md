# ecslib
## Easier and simpler game development with ECS
ecslib is a nimble package that implements a sparse set-based Entity Component System.

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
    # Get the resource of type `T`
    time: Resource[Time]
) {.system.} =
  # specifying components that will be used in the system
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

while true:
  world.runSystems()
```

> [!NOTE]
> This project adopts Design by Contract for implementation. Please build your app with `--assertions:off` to run without assertions.

## Installation
```nim
nimble install ecslib
```

## Documentation
See:
- [API.md](../docs/API.md) for basic usage
- [system_dsl.md](../docs/system_dsl.md) for system grammer

## License
ecslib is licensed under the MIT license. See COPYING for details.


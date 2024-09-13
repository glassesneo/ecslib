# System
when you attach `{.system.}` pragma to a procedure with certain arguments, then it's turned into a `System`.
```nim
proc addGravity*(
    query: [All[Rigidbody]],
    gravity: Resource[Gravity]
) {.system.} =
  for entity in query:
    let rb = entity.get(Rigidbody)
    if not rb.useGravity:
      continue

    let w = rb.mass * gravity.g
    rb.addForce(y = w)

# register your systems so that they will be called every frame
world.registerSystems(addGravity)
```

## arguments
`System` can take these kind of the arguments below:
- Query
- Resource[T]
- Event[T]

### Query
A sequence of entities queried by specifying what they have or what they don't. A query consists of these 3 constraints.
- All<br>
  entities that have **all** of the components.
- Any<br>
  entities that have **any** of the components.
- None<br>
  entities that have **none** of the components.

#### example
```nim
proc checkCollision*(
    # some game objects each of which has `Rigidbody`, `Transform`, and `RectangleCollider`
    objectQuery: [All[Rigidbody, Transform, RectangleCollider]]
) {.system.} =
  ...

proc changeColor*(
    # textures each of which has `Material`, and any of `Circle` and `Rectangle`
    textureQuery: [All[Material], Any[Circle, Rectangle]]
) {.system.} =
  ...
```

Also, multiple queries are allowed.
```nim
proc detectArrowCollision*(
    # entities each of which represents an arrow with `Rigidbody`
    arrowQuery: [All[Arrow, Rigidbody]],
    # enemies but their state is not `Dead`
    enemyQuery: [All[Enemy], None[Dead]]
) {.system.} =
  ...
```

### Resource[T]
A global variable of type `T`, which systems can refer to.

#### example
```nim
proc adjustFrame*(fpsManager: Resource[FPSManager]) {.system.} =
  ...

proc renderRectangle*(
    rectangles: [All[Rectangle, Transform, Material]],
    renderer: Resource[Renderer]
) {.system.} =
  ...
```

### Event[T]
An iterable object that has a queue of type `T`. The queue is cleared per a frame after all the systems receive the events.
For sending an event, please use `dispatchEvent[T]`.

#### example
```nim
proc pollEvent(appEvent: Event[ApplicationEvent]) {.system.} =
  for event in appEvent:
    if event.eventType == Quit:
      ...

proc changePlayerState(
    playerQuery: [All[Player]],
    keyboardEvent: Event[KeyboardEvent]
) {.system.} =
  for event in keyboardEvent:
    if event.isPressed(K_Space):
      ...
```


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
  entity that have **any** of the components.
- None<br>
  entity that have **none** of the components.

#### example
```nim
proc checkCollision*(
    objectQuery: [All[Rigidbody, Transform, RectangleCollider]]
    # some game objects each of which has `Rigidbody`, `Transform`, and `RectangleCollider`
) {.system.} =
  ...

proc changeColor*(
    textureQuery: [All[Material], Any[Circle, Rectangle]]
    # textures each of which has `Material`, and any of `Circle` and `Rectangle`
) {.system.} =
  ...
```

Also, multiple queries are allowed.
```nim
proc detectArrowCollision*(
    arrowQuery: [All[Arrow, Rigidbody]],
    # entities each of which represents an arrow with `Rigidbody`
    enemyQuery: [All[Enemy], None[Dead]]
    # enemies but their state is not `Dead`
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

## utility macros
```nim
macro each*(loop: ForLoopStmt): untyped
```
Iterates over a query and generates variables of specified component types. Each component is mutable. `O(n)` operation, where n is the length of a query.

### example
```nim
proc motion*(
    query: [All[Rigidbody, Transform]],
    fpsManager: Resource[FPSManager]
) {.system.} =
  let dt = fpsManager.deltaTime
  for rb, tf in each(query, [Rigidbody, Transform]):
    rb.velocity += rb.acceleration * dt
    tf.position += rb.velocity * dt
```
`each` takes a query as the 1st argument and an array of components as the 2nd argument.

<br><br>

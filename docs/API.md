# World
`World` manage everything for Entity Component System.

```nim
let world = World.new()

let entity = world.create()
```

## constructor
```nim
proc new*(_: type World): World
```

## fields
```nim
proc entities*(world: World): seq[Entity]
```
Returns all the entities alive.<br><br>

```nim
proc id*(entity: Entity): EntityId
```
Returns `entity`'s entity id.

## procedures
```nim
proc create*(world: World): Entity {.discardable.}
```
Creates a new entity.<br><br>

```nim
proc getEntity*(world: World, id: EntityId): Entity {.raises: [KeyError].}
```
Gets an entity by its id. `O(1)` operation. Raises `KeyError` when `id` doesn't exist.<br><br>

```nim
proc addResource*[T](world: World, data: T)
```
Adds a resource of type `T` to `world`.<br><br>

```nim
proc getResource*(world: World, T: typedesc): T {.raises: [KeyError].}
```
Gets a resource of type `T`. Raises `KeyError` when `T` doesn't exist.<br><br>

```nim
proc deleteResource*(world: World, T: typedesc)
```
Deletes a resource of type `T`.<br><br>

```nim
proc hasResource*(world: World, T: typedesc): bool
```
Returns whether a resource of type `T` exists or not.<br><br>

```nim
proc hasResource*(world: World, typeName: string): bool
```
Same as above, but takes `string` instead of `typedesc`.<br><br>

```nim
proc addEvent*(world: World, T: typedesc)
```
Initializes an event queue of type `T`.<br><br>

```nim
proc dispatchEvent*[T](world: World, data: T) {.raises: [KeyError].} =
```
Sends an event to the event queue of type `T`. `world.addEvent(T)` must be called.<br><br>

```nim
proc receiveEvent*(world: World, T: typedesc): Event[T] {.raises: [KeyError].}
```
Receives the event queue of type `T`. **DO NOT** call this procedure manually.<br><br>

```nim
proc runSystems*(world: World) {.raises: [Exception].}
```
Runs normal systems.<br><br>

```nim
proc runStartupSystems*(world: World) {.raises: [Exception].}
```
Runs startup systems.<br><br>

```nim
proc runTerminateSystems*(world: World) {.raises: [Exception].}
```
Runs terminate systems.<br><br>

## macros
```nim
macro updateResource*(world: World; args: untyped): untyped
```
Update a component. The notation for `args` is similar to object construction expression.

### example
```nim
world.updateResource(Position(x: 5, y: 0))
```
the code above is converted into:

```nim
block:
  let component = world.getResource(Position)
  component.x = 5
  component.y = 0
```<br><br>

```nim
macro registerSystems*(world: World, systems: varargs[untyped])
```
Registers `systems` to a normal system queue.<br><br>

```nim
macro registerStartupSystems*(world: World, systems: varargs[untyped])
```
Registers `systems` to a system queue that will run only once when the app starts.<br><br>

```nim
macro registerTerminateSystems*(world: World, systems: varargs[untyped])
```
Registers `systems` to a system queue that will run only once when the app quits.

# Entity
Entity represents a game object, which any ref types can be attached to. Only `World` can create a new one.

## fields
```nim
proc id*(entity: Entity): EntityId
```
Returns `entity`'s unique id.<br><br>

## procedures
```nim
proc hash*(entity: Entity): Hash
```
A hash function for entity used to make it a key for `Table`.<br><br>

```nim
proc `$`*(entity: Entity): string
```
Converts `entity` to a string.<br><br>

```nim
proc isValid*(entity: Entity): bool
```
Return whether `entity` is valid.<br><br>

```nim
proc has*(entity: Entity, T: typedesc): bool {.raises: [KeyError].}
```
Return whether `entity` has a component of type `T` attached to it.<br><br>

```nim
proc has*(entity: Entity, typeName: string): bool {.raises: [KeyError].}
```
Same as above, but takes `string` instead of `typedesc`.<br><br>

```nim
proc attach*[T](entity: Entity, data: T): Entity {.raises: [KeyError], discardable.}
```
Attaches a component of type `T` to `entity`.<br><br>

```nim
proc withBundle*(entity: Entity, bundle: tuple): Entity {.raises: [KeyError], discardable.}
```
Attaches every component in `bundle` to `entity`. Used to make a bundle function.<br><br>

```nim
proc get*(entity: Entity, T: typedesc): T {.raises: [KeyError].}
```
Gets a component of type `T` attached to `entity`. Raises `KeyError` if `entity` doesn't have it.<br><br>

```nim
proc `[]`*(entity: Entity, T: typedesc): T {.raises: [KeyError].}
```
An alias for `entity.get(T)`.<br><br>

```nim
proc `[]`*(entity: Entity, T, U: typedesc): (T, U) {.raises: [KeyError].}
```
Returns `(entity.get(T), entity.get(U))`.<br><br>

```nim
proc `[]`*(entity: Entity, T, U, V: typedesc): (T, U, V) {.raises: [KeyError].}
```
Returns `(entity.get(T), entity.get(U), entity.get(V))`.<br><br>

```nim
proc `[]`*(entity: Entity, T, U, V, W: typedesc): (T, U, V, W) {.raises: [KeyError].}
```
Returns `(entity.get(T), entity.get(U), entity.get(V), entity.get(W))`.<br><br>

```nim
proc `[]=`*(entity: Entity, T: typedesc, data: T) {.raises: [KeyError].}
```
An alias for `let component = entity[T]; component = data`.<br><br>

```nim
proc detach*(entity: Entity, T: typedesc) {.raises: [KeyError].}
```
Detaches a component of type `T` from `entity`. Raises `KeyError` if `entity` doesn't have it.<br><br>

```nim
proc delete*(entity: Entity)
```
Deletes `entity`. You can still refer to `entity`, but its id will be invalid.

# Event
Event is an object that notifies systems that:
- a key is pressed
- a button is clicked
- two rigid body collides etc.

## procedures
```nim
proc len*[T](event: Event[T]): Natural
```
Returns the length of `event` queue.<br><br>

```nim
proc checkReferenceCount*[T](event: Event[T])
```
Checks reference count for `event`. **DO NOT** call this procedure manually.<br><br>

```nim
proc clearQueue*[T](event: Event[T])
```
Clear `event` queue.

## iterators
```nim
iterator items*[T](event: Event[T]): T
```
Iterates over `event` queue.<br><br>

# Commands
Commands is a limited version of `World` that only exists in `System`.

## procedures
```nim
proc create*(commands: Commands): Entity {.discardable.}
```
Creates a new entity.<br><br>

```nim
proc getEntity*(commands: Commands, id: EntityId): Entity {.raises: [KeyError].}
```
Gets an entity by its id. `O(1)` operation. Raises `KeyError` when `id` doesn't exist.<br><br>

```nim
proc addResource*[T](commands: Commands, data: T)
```
Adds a resource of type `T` to `world`.<br><br>

```nim
proc getResource*(commands: Commands, T: typedesc): T {.raises: [KeyError].}
```
Gets a resource of type `T`. Raises `KeyError` when `T` doesn't exist.<br><br>

```nim
proc hasResource*(commands: Commands, T: typedesc): bool
```
Returns whether a resource of type `T` exists or not.<br><br>

```nim
proc hasResource*(commands: Commands, typeName: string): bool
```
Same as above, but takes `string` instead of `typedesc`.<br><br>

```nim
proc dispatchEvent*[T](commands: Commands, data: T) {.raises: [KeyError].}
```
Sends an event to the event queue of type `T`. `world.addEvent(T)` must be called.<br><br>

```nim
proc receiveEvent*(commands: Commands, T: typedesc): Event[T] {.raises: [KeyError].}
```
Receives the event queue of type `T`. **DO NOT** call this procedure manually.

## macros
```nim
macro updateResource*(commands: Commands; args: untyped): untyped
```
Updates a component. Same usage as `world.updateResource(T())`<br><br>


import
  std/hashes,
  std/tables,
  std/typetraits

type
  EntityId* = uint

  AbstructComponent = ref object of RootObj
    indexTable: Table[Entity, int]
    freeIndex: seq[int]

  Component[T] = ref object of AbstructComponent
    storage: seq[T]

  World* = ref object
    nextId: EntityId
    freeIds: seq[EntityId]
    entities: seq[Entity]
    components: Table[string, AbstructComponent]

  Entity* = ref object
    id: EntityId
    world: World

const InvalidEntityId*: EntityId = 0

proc hash*(entity: Entity): Hash {.inline.} =
  entity.id.hash()

proc new[T](_: type Component[T]): Component[T] = Component[T]()

proc new(_: type Entity, id: uint, world: World): Entity =
  return Entity(id: id, world: world)

proc new*(_: type World): World =
  World(nextId: 1)

proc `[]`[T](component: Component[T], entity: Entity): T =
  return component.storage[component.indexTable[entity]]

proc `[]=`[T](component: Component[T], entity: Entity, value: T) =
  if component.indexTable.hasKey(entity):
    component.storage[component.indexTable[entity]] = value
    return

  if component.freeIndex.len > 0:
    component.indexTable[entity] = component.freeIndex.pop
    component.storage[component.indexTable[entity]] = value
    return

  component.indexTable[entity] = component.storage.len
  component.storage.add(value)

proc attachToEntity[T](component: Component[T], data: T, entity: Entity) =
  component[entity] = data

proc has(component: AbstructComponent, entity: Entity): bool =
  return component.indexTable.hasKey(entity)

proc deleteEntity(component: AbstructComponent, entity: Entity) =
  component.indexTable.del(entity)

proc create*(world: World): Entity {.discardable.} =
  if world.freeIds.len == 0:
    result = Entity.new(world.nextId, world)
    world.nextId += 1
  else:
    result = Entity.new(world.freeIds.pop, world)

  world.entities.add result

proc componentOf(world: World, T: typedesc): Component[T] =
  cast[Component[T]](world.components[T.name])

proc has(world: World, T: typedesc): bool =
  return world.components.hasKey(T.name)

proc isInvalidEntity(world: World, entity: Entity): bool =
  return entity.id notin world.freeIds

proc attachComponent[T](world: World, data: T, entity: Entity) =
  if not world.components.hasKey(T.name):
    world.components[T.name] = Component[T].new()

  world.componentOf(T).attachToEntity(data, entity)

proc getComponent(world: World, T: typedesc, entity: Entity): T =
  if not (world.has(T) and world.componentOf(T).has(entity)):
    raise Exception.newException:
      "Entity(id: " & $entity.id & ") does not have " & $T.name

  if entity.id in world.freeIds:
    raise Exception.newException:
      "Entity(id: " & $entity.id & ") does not exist"

  return world.componentOf(T)[entity]

proc detachComponent(world: World, T: typedesc, entity: Entity) =
  world.componentOf(T).deleteEntity(entity)

proc deleteEntity(world: World, entity: Entity) =
  world.freeIds.add(entity.id)
  for c in world.components.values:
    c.deleteEntity(entity)

proc isValid*(entity: Entity): bool =
  entity.world.isInvalidEntity(entity)

proc attach*[T](entity: Entity, data: T): Entity {.discardable.} =
  entity.world.attachComponent(data, entity)
  return entity

proc has*(entity: Entity, T: typedesc): bool =
  return entity.world.has(T) and entity.world.componentOf(T).has(entity)

proc get*(entity: Entity, T: typedesc): T =
  return entity.world.getComponent(T, entity)

proc `[]`*(entity: Entity, T: typedesc): T =
  return entity.get(T)

proc `[]=`*(entity: Entity, T: typedesc, data: T) =
  entity.attach(data)

proc detach*(entity: Entity, T: typedesc) =
  entity.world.detachComponent(T, entity)

proc delete*(entity: Entity) =
  entity.world.deleteEntity(entity)
  entity.id = InvalidEntityId

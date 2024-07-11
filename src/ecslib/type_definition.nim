import
  std/hashes,
  std/macros,
  std/sequtils,
  std/tables,
  std/typetraits

type
  EntityId* = uint

  Entity* = ref object
    id: EntityId
    world*: World

  AbstractComponent* = ref object of RootObj
    indexTable: Table[Entity, int]
    freeIndex: seq[int]

  Component*[T] = ref object of AbstractComponent
    storage: seq[T]

  AbstractResource* = ref object of RootObj

  Resource*[T] = ref object of AbstractResource
    data: T

  World* = ref object
    nextId: EntityId
    freeIds: seq[EntityId]
    commands: Commands
    entities: seq[Entity]
    components: Table[string, AbstractComponent]
    resources: Table[string, AbstractResource]
    systems, startupSystems, terminateSystems: seq[System]

  Query = proc(entity: Entity): bool

  Process = proc(entities: seq[Entity], commands: Commands)

  System* = ref object
    targetedEntities: seq[Entity]
    query: Query
    process: Process

  Commands* = ref object
    world: World

const InvalidEntityId*: EntityId = 0

proc hash*(entity: Entity): Hash {.inline.} =
  entity.id.hash()

proc new[T](_: type Component[T]): Component[T] = Component[T]()

proc new(_: type Entity, id: uint, world: World): Entity =
  return Entity(id: id, world: world)

proc create*(world: World): Entity {.discardable.} =
  if world.freeIds.len == 0:
    result = Entity.new(world.nextId, world)
    world.nextId += 1
  else:
    result = Entity.new(world.freeIds.pop, world)

  world.entities.add result

proc `[]`[T](component: Component[T], entity: Entity): T =
  return component.storage[component.indexTable[entity]]

proc `[]=`[T](component: Component[T], entity: Entity, value: T) =
  if entity in component.indexTable:
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

proc has(component: AbstractComponent, entity: Entity): bool =
  return entity in component.indexTable

proc deleteEntity(component: AbstractComponent, entity: Entity) =
  component.indexTable.del(entity)

iterator items*[T](component: Component[T]): T =
  for i in component.indexTable.values:
    yield component.storage[i]

iterator pairs*[T](component: Component[T]): tuple[key: Entity, val: T] =
  for e, i in component.indexTable.pairs:
    yield (e, component.storage[i])

proc new*(_: type Commands, world: World): Commands =
  return Commands(world: world)

proc new*(_: type World): World =
  result = World(nextId: 1)
  result.commands = Commands.new(result)

proc entities*(world: World): seq[Entity] =
  world.entities

proc resourceOf(world: World, T: typedesc): Resource[T] =
  return cast[Resource[T]](world.resources[typetraits.name(T)])

proc addResource*[T](world: World, data: T) =
  world.resources[typetraits.name(T)] = Resource[T](data: data)

proc getResource*(world: World, T: typedesc): T =
  return world.resourceOf(T).data

proc deleteResource*(world: World, T: typedesc) =
  world.resources.del(typetraits.name(T))

proc componentOf*(world: World, T: typedesc): Component[T] =
  return cast[Component[T]](world.components[typetraits.name(T)])

proc has(world: World, T: typedesc): bool =
  return typetraits.name(T) in world.components

proc has(world: World, typeName: string): bool =
  return typeName in world.components

proc isInvalidEntity*(world: World, entity: Entity): bool =
  return entity.id notin world.freeIds

proc attachComponent[T](world: World, data: T, entity: Entity) =
  if typetraits.name(T) notin world.components:
    world.components[typetraits.name(T)] = Component[T].new()

  world.componentOf(T).attachToEntity(data, entity)

proc getComponent(world: World, T: typedesc, entity: Entity): T =
  return world.componentOf(T)[entity]

proc detachComponent(world: World, T: typedesc, entity: Entity) =
  world.componentOf(T).deleteEntity(entity)

proc deleteEntity(world: World, entity: Entity) =
  world.freeIds.add(entity.id)
  for c in world.components.values:
    c.deleteEntity(entity)

proc id*(entity: Entity): EntityId =
  return entity.id

proc `$`*(entity: Entity): string =
  return "Entity(id: " & $entity.id & ")"

proc isValid*(entity: Entity): bool =
  entity.world.isInvalidEntity(entity)

proc attach*[T](entity: Entity, data: T): Entity {.discardable.} =
  entity.world.attachComponent(data, entity)
  return entity

proc withBundle*(entity: Entity, bundle: tuple): Entity {.discardable.} =
  for c in bundle.fields:
    entity.attach(c)
  return entity

proc has*(entity: Entity, T: typedesc): bool =
  return entity.world.has(T) and entity.world.componentOf(T).has(entity)

proc has*(entity: Entity, typeName: string): bool =
  return entity.world.has(typeName) and entity.world.components[typeName].has(entity)

proc hasAll*(entity: Entity, typeNames: seq[string]): bool =
  result = true
  for t in typeNames:
    if not entity.has(t):
      return false

proc hasAny*(entity: Entity, typeNames: seq[string]): bool =
  if typeNames.len == 0:
    return true
  result = false
  for t in typeNames:
    if entity.has(t):
      return true

proc hasNone*(entity: Entity, typeNames: seq[string]): bool =
  if typeNames.len == 0:
    return true
  return not entity.hasAny(typeNames)

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

proc new*(_: type System, query: Query, process: Process): System =
  return System(
    query: query,
    process: process,
  )

proc updateTargets(system: System, world: World) =
  system.targetedEntities = world.entities.filter(system.query)

proc update*(system: System, world: World) =
  system.updateTargets(world)
  system.process(system.targetedEntities, world.commands)

proc registerSystems*(world: World, systems: varargs[System]) =
  world.systems.add systems

proc registerStartupSystems*(world: World, systems: varargs[System]) =
  world.startupSystems.add systems

proc registerTerminateSystems*(world: World, systems: varargs[System]) =
  world.terminateSystems.add systems

proc runSystems*(world: World) =
  for system in world.systems:
    system.update(world)

proc runStartupSystems*(world: World) =
  for system in world.startupSystems:
    system.update(world)

proc runTerminateSystems*(world: World) =
  for system in world.terminateSystems:
    system.update(world)

proc create*(commands: Commands): Entity {.discardable.} =
  return commands.world.create()

proc addResource*[T](commands: Commands, data: T) =
  commands.world.addResource(data)

proc getResource*(commands: Commands, T: typedesc): T =
  return commands.world.getResource(T)

proc registerSystems*(commands: Commands, systems: varargs[System]) =
  commands.world.registerSystems(systems)


{.push raises: [].}

import
  std/[
    hashes,
    macros,
    macrocache,
    sequtils,
    setutils,
    tables,
    typetraits
  ]

type
  World* = ref object
    nextId: EntityId
    freeIds: seq[EntityId]
    commands: Commands
    entities: seq[Entity]
    idIndexMap: Table[EntityId, Entity]
    components: Table[string, AbstractComponent]
    resources: Table[string, AbstractResource]
    events: Table[string, AbstractEvent]
    eventReceiptCounter: Table[string, int]
    systems, startupSystems, terminateSystems: OrderedTable[string, System]
    systemSpecTable: Table[string, SystemSpec]
    runtimeQueryTable: Table[string, Table[string, seq[Entity]]]

  EntityId* = uint16

  Entity* = ref object
    id: EntityId
    world*: World

  AbstractComponent* = ref object of RootObj
    entityIdSet*: set[EntityId]
    indexTable: Table[Entity, int]
    freeIndex: seq[int]

  Component*[T] = ref object of AbstractComponent
    storage: seq[T]

  AbstractResource* = ref object of RootObj

  Resource*[T] = ref object of AbstractResource
    data: T

  AbstractEvent* = ref object of RootObj
    refCount: int

  Event*[T] = ref object of AbstractEvent
    queue: seq[T]

  System* = proc(
    commands: Commands,
    queryPack: Table[string, seq[Entity]]
  ) {.nimcall.}

  Query* = tuple
    qAll, qAny, qNone: seq[string]

  SystemSpec* = tuple
    queryTable: Table[string, Query]
    eventList: seq[string]

  Commands* = ref object
    world: World

const systemTable* = CacheTable"systemTable"

const specTable* = CacheTable"specTable"

const InvalidEntityId*: EntityId = 0

proc new*(_: type Commands, world: World): Commands =
  return Commands(world: world)

proc new*(_: type World): World =
  result = World(nextId: 1)
  result.commands = Commands.new(result)

proc new(_: type Entity, id: EntityId, world: World): Entity =
  return Entity(id: id, world: world)

proc new[T](_: type Component[T]): Component[T] = Component[T]()

proc resourceOf(world: World, T: typedesc): Resource[T] {.raises: [KeyError].} =
  return cast[Resource[T]](world.resources[typetraits.name(T)])

proc componentOf*(world: World, T: typedesc): Component[T] {.raises: [KeyError].} =
  return cast[Component[T]](world.components[typetraits.name(T)])

proc has(world: World, T: typedesc): bool =
  return typetraits.name(T) in world.components

proc has(world: World, typeName: string): bool =
  return typeName in world.components

proc getOrEmpty*(world: World, T: string): set[EntityId] {.raises: [KeyError].} =
  return if world.has(T):
    world.components[T].entityIdSet
  else:
    {}

proc hash*(entity: Entity): Hash {.inline.} =
  entity.id.hash()

proc has(component: AbstractComponent, entity: Entity): bool =
  return entity.id in component.entityIdSet

proc `[]`[T](component: Component[T], entity: Entity): T {.raises: [KeyError].} =
  return component.storage[component.indexTable[entity]]

proc `[]=`[T](component: Component[T], entity: Entity, value: T) {.raises: [KeyError].} =
  if component.has(entity):
    component.storage[component.indexTable[entity]] = value
    return

  if component.freeIndex.len > 0:
    let index = component.freeIndex.pop()
    component.indexTable[entity] = index
    component.entityIdSet.incl entity.id
    component.storage[index] = value
    return

  component.indexTable[entity] = component.storage.len
  component.entityIdSet.incl entity.id
  component.storage.add(value)

proc deleteEntity(component: AbstractComponent, entity: Entity) =
  component.indexTable.del(entity)
  component.entityIdSet.excl entity.id

proc attachComponent[T](world: World, data: T, entity: Entity) {.raises: [KeyError].} =
  if typetraits.name(T) notin world.components:
    world.components[typetraits.name(T)] = Component[T].new()

  world.componentOf(T)[entity] = data

proc getComponent(world: World, T: typedesc, entity: Entity): T {.raises: [KeyError].} =
  return world.componentOf(T)[entity]

proc detachComponent(world: World, T: typedesc, entity: Entity) {.raises: [KeyError].} =
  world.componentOf(T).deleteEntity(entity)

proc deleteEntity(world: World, entity: Entity) =
  world.idIndexMap.del(entity.id)
  world.freeIds.add(entity.id)
  for c in world.components.values:
    c.deleteEntity(entity)

proc fullEntityIdSet(world: World): set[EntityId] =
  return world.entities.mapIt(it.id).toSet()

proc intersection(
    world: World,
    targets: seq[string]
): set[EntityId] {.raises: [KeyError].} =
  result = targets
    .mapIt(world.getOrEmpty(it)).foldl(a * b)

proc union(
    world: World,
    targets: seq[string]
): set[EntityId] {.raises: [KeyError].} =
  result = targets
    .mapIt(world.getOrEmpty(it)).foldl(a + b)

proc queryEntities(
    world: World,
    query: Query
): set[EntityId] {.raises: [KeyError].} =
  let qAll = case query.qAll.len
    of 0: world.fullEntityIdSet
    of 1: world.getOrEmpty(query.qAll[0])
    else: world.intersection(query.qAll)

  let qAny = case query.qAny.len
    of 0: world.fullEntityIdSet
    of 1: world.getOrEmpty(query.qAny[0])
    else: world.union(query.qAny)

  let qNone = case query.qNone.len
    of 0: {}
    of 1: world.getOrEmpty(query.qNone[0])
    else: world.union(query.qNone)

  result = qAll * qAny - qNone
  result.excl InvalidEntityId

proc update(system: System, systemName: string, world: World) {.raises: [Exception].} =
  let spec = world.systemSpecTable[systemName]
  for queryName, query in spec.queryTable:
    let targetedEntities = world.queryEntities(query)
    world.runtimeQueryTable[systemName][queryName] = targetedEntities.mapIt(
      world.idIndexMap[it]
    )

  system(world.commands, world.runtimeQueryTable[systemName])

proc create*(world: World): Entity {.discardable.} =
  if world.freeIds.len == 0:
    result = Entity.new(world.nextId, world)
    world.nextId += 1
  else:
    result = Entity.new(world.freeIds.pop, world)

  world.entities.add result
  world.idIndexMap[result.id] = result

proc entities*(world: World): seq[Entity] =
  return world.entities

proc getEntity*(world: World, id: EntityId): Entity {.raises: [KeyError].} =
  return world.idIndexMap[id]

proc isInvalidEntity(world: World, entity: Entity): bool =
  return entity.id == InvalidEntityId

proc addResource*[T](world: World, data: T) =
  world.resources[typetraits.name(T)] = Resource[T](data: data)

proc getResource*(world: World, T: typedesc): T {.raises: [KeyError].} =
  return world.resourceOf(T).data

proc deleteResource*(world: World, T: typedesc) =
  world.resources.del(typetraits.name(T))

proc hasResource*(world: World, T: typedesc): bool =
  return typetraits.name(T) in world.resources

proc hasResource*(world: World, typeName: string): bool =
  return typeName in world.resources

macro updateResource*(world: World; args: untyped): untyped =
  args.expectKind(nnkObjConstr)
  let componentName = ident"component"
  let T = args[0]
  var assignmentList: seq[NimNode]

  for node in args[1..^1]:
    let
      name = node[0]
      value = node[1]

    assignmentList.add quote do:
      `componentName`.`name` = `value`

  result = quote do:
    block:
      let `componentName` = `world`.getResource(`T`)

  for assignment in assignmentList:
    result[1].add assignment

proc eventOf*(world: World, T: typedesc): Event[T] {.raises: [KeyError].} =
  return cast[Event[T]](world.events[typetraits.name(T)])

proc addEvent*(world: World, T: typedesc) =
  let typeName = typetraits.name(T)
  world.events[typeName] = Event[T](
    refCount: 0,
    queue: newSeq[T](),
  )
  world.eventReceiptCounter[typeName] = 0

proc dispatchEvent*[T](world: World, data: T) {.raises: [KeyError].} =
  let event = world.eventOf(T)
  event.queue.add data
  event.refCount = world.eventReceiptCounter[typetraits.name(T)]

proc receiveEvent*(world: World, T: typedesc): Event[T] {.raises: [KeyError].} =
  result = world.eventOf(T)
  if result.queue.len != 0:
    result.refCount -= 1

proc id*(entity: Entity): EntityId =
  return entity.id

proc `$`*(entity: Entity): string =
  return "Entity(id: " & $entity.id & ")"

proc isValid*(entity: Entity): bool =
  not entity.world.isInvalidEntity(entity)

proc has*(entity: Entity, T: typedesc): bool {.raises: [KeyError].} =
  return entity.world.has(T) and entity.world.componentOf(T).has(entity)

proc has*(entity: Entity, typeName: string): bool {.raises: [KeyError].} =
  return entity.world.has(typeName) and entity.world.components[typeName].has(entity)

proc hasAll*(entity: Entity, typeNames: seq[string]): bool {.raises: [KeyError].} =
  result = true
  for t in typeNames:
    if not entity.has(t):
      return false

proc hasAny*(entity: Entity, typeNames: seq[string]): bool {.raises: [KeyError].} =
  if typeNames.len == 0:
    return true
  result = false
  for t in typeNames:
    if entity.has(t):
      return true

proc hasNone*(entity: Entity, typeNames: seq[string]): bool {.raises: [KeyError].} =
  if typeNames.len == 0:
    return true
  return not entity.hasAny(typeNames)

proc attach*[T](
    entity: Entity,
    data: T
): Entity {.raises: [KeyError], discardable.} =
  entity.world.attachComponent(data, entity)
  return entity

proc withBundle*(
    entity: Entity,
    bundle: tuple
): Entity {.raises: [KeyError], discardable.} =
  for c in bundle.fields:
    entity.attach(c)
  return entity

proc get*(entity: Entity, T: typedesc): T {.raises: [KeyError].} =
  return entity.world.getComponent(T, entity)

proc `[]`*(entity: Entity, T: typedesc): T {.raises: [KeyError].} =
  return entity.get(T)

proc `[]=`*(entity: Entity, T: typedesc, data: T) {.raises: [KeyError].} =
  entity.attach(data)

proc detach*(entity: Entity, T: typedesc) {.raises: [KeyError].} =
  entity.world.detachComponent(T, entity)

proc delete*(entity: Entity) =
  entity.world.deleteEntity(entity)
  entity.id = InvalidEntityId

macro registerSystems*(world: World, systems: varargs[untyped]) =
  result = newStmtList()
  for system in systems:
    let
      systemName = system.strVal
      systemSpec = specTable[systemName]
      systemNameLit = systemName.newLit()

    result.add quote do:
      `world`.systems[`systemNameLit`] = `system`
      `world`.systemSpecTable[`systemNameLit`] = `systemSpec`
      `world`.runtimeQueryTable[`systemNameLit`] =
        initTable[string, seq[Entity]]()
      for queryName in `systemSpec`.queryTable.keys():
        `world`.runtimeQueryTable[`systemNameLit`][queryName] = @[]

macro registerStartupSystems*(world: World, systems: varargs[untyped]) =
  result = newStmtList()
  for system in systems:
    let
      systemName = system.strVal
      systemSpec = specTable[systemName]
      systemNameLit = systemName.newLit()

    result.add quote do:
      `world`.startupSystems[`systemNameLit`] = `system`
      `world`.systemSpecTable[`systemNameLit`] = `systemSpec`
      `world`.runtimeQueryTable[`systemNameLit`] =
        initTable[string, seq[Entity]]()
      for queryName in `systemSpec`.queryTable.keys():
        `world`.runtimeQueryTable[`systemNameLit`][queryName] = @[]

macro registerTerminateSystems*(world: World, systems: varargs[untyped]) =
  result = newStmtList()
  for system in systems:
    let
      systemName = system.strVal
      systemSpec = specTable[systemName]
      systemNameLit = systemName.newLit()

    result.add quote do:
      `world`.terminateSystems[`systemNameLit`] = `system`
      `world`.systemSpecTable[`systemNameLit`] = `systemSpec`
      `world`.runtimeQueryTable[`systemNameLit`] =
        initTable[string, seq[Entity]]()
      for queryName in `systemSpec`.queryTable.keys():
        `world`.runtimeQueryTable[`systemNameLit`][queryName] = @[]

proc runSystems*(world: World) {.raises: [Exception].} =
  for key in world.eventReceiptCounter.keys():
    world.eventReceiptCounter[key] = 0

  for name in world.systems.keys():
    let spec = world.systemSpecTable[name]
    for T in spec.eventList:
      world.eventReceiptCounter[T] += 1

  for name, system in world.systems:
    system.update(name, world)

proc runStartupSystems*(world: World) {.raises: [Exception].} =
  for name, system in world.startupSystems:
    system.update(name, world)

proc runTerminateSystems*(world: World) {.raises: [Exception].} =
  var nameList: seq[string]
  for name in world.terminateSystems.keys():
    nameList = name & nameList
  for name in nameList:
    let system = world.terminateSystems[name]
    system.update(name, world)

proc len*[T](event: Event[T]): Natural =
  return event.queue.len()

iterator items*[T](event: Event[T]): T =
  for v in event.queue:
    yield v

proc checkReferenceCount*[T](event: Event[T]) =
  if event.refCount <= 0:
    event.queue = @[]

proc clearQueue*[T](event: Event[T]) =
  event.queue = @[]

proc create*(commands: Commands): Entity {.discardable.} =
  return commands.world.create()

proc getEntity*(commands: Commands, id: EntityId): Entity {.raises: [KeyError].} =
  return commands.world.getEntity(id)

proc addResource*[T](commands: Commands, data: T) =
  commands.world.addResource(data)

proc getResource*(commands: Commands, T: typedesc): T {.raises: [KeyError].} =
  return commands.world.getResource(T)

proc hasResource*(commands: Commands, T: typedesc): bool =
  return commands.world.hasResource(T)

proc hasResource*(commands: Commands, typeName: string): bool =
  return commands.world.hasResource(typeName)

macro updateResource*(commands: Commands; args: untyped): untyped =
  args.expectKind(nnkObjConstr)
  let componentName = ident"component"
  let T = args[0]
  var assignmentList: seq[NimNode]

  for node in args[1..^1]:
    let
      name = node[0]
      value = node[1]

    assignmentList.add quote do:
      `componentName`.`name` = `value`

  result = quote do:
    block:
      let `componentName` = `commands`.world.getResource(`T`)

  for assignment in assignmentList:
    result[1].add assignment

proc eventOf*(commands: Commands, T: typedesc): Event[T] {.raises: [KeyError].} =
  return commands.world.eventOf(T)

proc dispatchEvent*[T](commands: Commands, data: T) {.raises: [KeyError].} =
  commands.world.dispatchEvent(data)

proc receiveEvent*(commands: Commands, T: typedesc): Event[T] {.raises: [KeyError].} =
  return commands.world.receiveEvent(T)


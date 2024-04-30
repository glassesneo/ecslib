import
  std/hashes,
  std/macros,
  std/sets,
  std/sequtils,
  std/strformat,
  std/sugar,
  std/tables,
  std/typetraits,
  ./exceptions

type
  EntityId* = uint

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
    entities: seq[Entity]
    components: Table[string, AbstractComponent]
    resources: Table[string, AbstractResource]

  Command* = ref object
    world: World

  Entity* = ref object
    id: EntityId
    world*: World

  Query* = ref object
    componentSet: seq[string]
    process: (Entity) -> bool
    world: World

  Parent* = object
    children*: HashSet[Entity]

  Child* = object
    parent*: Entity

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

proc has(component: AbstractComponent, entity: Entity): bool =
  return component.indexTable.hasKey(entity)

proc deleteEntity(component: AbstractComponent, entity: Entity) =
  component.indexTable.del(entity)

iterator items*[T](component: Component[T]): T =
  for i in component.indexTable.values:
    yield component.storage[i]

iterator pairs*[T](component: Component[T]): tuple[key: Entity, val: T] =
  for e, i in component.indexTable.pairs:
    yield (e, component.storage[i])

proc new*(_: type World): World =
  return World(nextId: 1)

proc entities*(world: World): seq[Entity] =
  world.entities

proc addResource*[T](world: World, data: T) =
  world.resources[T.name] = Resource[T](data: data)

proc getResource*(world: World, T: typedesc): T =
  return world.reesourceOf(T).data

proc deleteResource*(world: World, T: typedesc) =
  world.resources.del(T.name)

proc reesourceOf*(world: World, T: typedesc): Resource[T] =
  return cast[Resource[T]](world.resources[T.name])

proc componentOf*(world: World, T: typedesc): Component[T] =
  return cast[Component[T]](world.components[T.name])

proc has(world: World, T: typedesc): bool =
  return world.components.hasKey(T.name)

proc has(world: World, typeName: string): bool =
  return world.components.hasKey(typeName)

proc isInvalidEntity*(world: World, entity: Entity): bool =
  return entity.id notin world.freeIds

proc attachComponent[T](world: World, data: T, entity: Entity) =
  if not world.components.hasKey(T.name):
    world.components[T.name] = Component[T].new()

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
  return fmt"Entity(id: {entity.id})"

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

template withComponent*(entity: Entity, T: typedesc; body: untyped) =
  var component {.inject.} = entity.get(T)
  body
  entity[T] = component

proc registerParent*(entity, parent: Entity): Entity {.discardable.} =
  if entity.has(Child):
    raise (ref ParentDuplicationError)(
      msg: fmt"entity(id: {entity.id}) already has the parent entity(id: {parent.id})"
    )

  if parent.has(Parent):
    parent.withComponent(Parent):
      component.children.incl entity

  else:
    parent.attach(Parent(children: [entity].toHashSet()))

  return entity.attach(Child(parent: parent))

proc addChildren*(
    entity: Entity,
    children: varargs[Entity]
): Entity {.discardable.} =
  for child in children:
    child.registerParent(entity)

  return entity

proc clearChildren*(entity: Entity) =
  for child in entity.get(Parent).children:
    child.detach(Child)
  entity.detach(Parent)

proc removeChildren*(entity: Entity, children: varargs[Entity]) =
  entity.withComponent(Parent):
    for child in children:
      component.children.excl child

proc removeParent*(entity: Entity) =
  let parentEntity = entity.get(Child).parent
  parentEntity.clearChildren()

proc new*(_: type Command, world: World): Command =
  return Command(world: world)

proc create*(command: Command): Entity {.discardable.} =
  return command.world.create()

proc entities*(command: Command): seq[Entity] =
  command.world.entities

proc componentOf*(command: Command, T: typedesc): Component[T] =
  return command.world.componentOf(T)

proc addResource*[T](command: Command, data: T) =
  command.world.addResource[T](data)

proc getResource*(command: Command, T: typedesc): T =
  command.world.getResource(T)

proc deleteResource*(command: Command, T: typedesc) =
  command.world.deleteResource(T)

proc createQuery*(
    world: World,
    qAll: seq[string],
    qAny: seq[string] = @[],
    qNone: seq[string] = @[]
): Query =
  return Query(
    componentSet: qAll,
    process: (e: Entity) =>
      e.hasAll(qAll) and e.hasAny(qAny) and e.hasNone(qNone),
    world: world
  )

proc queriedEntities*(query: Query): seq[Entity] =
  return query.world.entities.filter(query.process)


import
  std/macros,
  std/sequtils,
  std/tables,
  ./type_definition

type
  EntityQuery* = ref object
    entities*: seq[Entity]

macro system*(theProc: untyped): untyped =
  # proc f(query: [All(Position), Any(Attack, Magic), None()])
  let queryTableIdentDef = theProc.params[1]

  var queryTable: Table[string, seq[string]] = initTable[string, seq[string]]()
  queryTable["All"] = @[]
  queryTable["Any"] = @[]
  queryTable["None"] = @[]

  for node in queryTableIdentDef[1][0..^1]:
    if node.kind != nnkCall:
      error "Unsupported syntax", node

    if node[0].strVal notin queryTable.keys.toSeq:
      error "Unsupported syntax", node[0]

    for c in node[1..^1]:
      queryTable[node[0].strVal].add c.strVal

  let systemBody = theProc.body

  block:
    let
      All = newLit(queryTable["All"])
      Any = newLit(queryTable["Any"])
      None = newLit(queryTable["None"])
    systemBody.insert 0, quote do:
      proc getEntityQuery(world: World): EntityQuery =
        result = EntityQuery.new()
        for e in world.entities:
          if e.hasAll(`All`) and e.hasAny(`Any`) and e.hasNone(`None`):
            result.entities.add e

  result = newProc(
    name = theProc[0],
    params = [newEmptyNode(), newIdentDefs(ident"world", ident"World")],
    body = systemBody
  )

macro each*(systemLoop: ForLoopStmt): untyped =
  result = nnkForStmt.newTree()

  let componentIdents = systemLoop[0..^3]
  let componentNames = systemLoop[^2][1..^1]
  let forBody = systemLoop[^1]

  result.add ident"entity"
  result.add ident"getEntityQuery".newCall(ident"world").newDotExpr(ident"entities")

  for (ident, typeName) in zip(componentIdents, componentNames):
    forBody.insert 0, quote do:
      let `ident` = entity.get(`typeName`)

  result.add forBody

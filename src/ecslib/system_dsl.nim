import
  std/macros,
  std/sequtils,
  std/tables,
  ./type_definition

macro system*(theProc: untyped): untyped =
  # proc f(all = [Position], any = [Attack, Magic], none = [])
  if theProc.params.len <= 1:
    return newProc(
      name = theProc[0],
      params = [newEmptyNode(), newIdentDefs(ident"command", ident"Command")],
      body = theProc.body
    )

  let queryIdentDefs = theProc.params[1..^1]

  var queryTable: Table[string, seq[string]] = initTable[string, seq[string]]()
  queryTable["all"] = @[]
  queryTable["any"] = @[]
  queryTable["none"] = @[]

  for node in queryIdentDefs:
    if node[2].kind != nnkBracket:
      error "Unsupported syntax", node

    let key = node[0].strVal
    if key notin queryTable.keys.toSeq:
      error "Unsupported syntax", node[0]

    for c in node[2][0..^1]:
      let name = block:
        if c.kind == nnkVarTy: c[0].strVal
        else: c.strVal
      queryTable[key].add name

  let systemBody = theProc.body

  block:
    let
      All = newLit(queryTable["all"])
      Any = newLit(queryTable["any"])
      None = newLit(queryTable["none"])
    systemBody.insert 0, quote do:
      proc getQueriedEntities(command: Command): seq[Entity] =
        for e in command.entities:
          if e.hasAll(`All`) and e.hasAny(`Any`) and e.hasNone(`None`):
            result.add e

  result = newProc(
    name = theProc[0],
    params = [newEmptyNode(), newIdentDefs(ident"command", ident"Command")],
    body = systemBody
  )

macro each*(systemLoop: ForLoopStmt): untyped =
  result = nnkForStmt.newTree()

  let componentIdents = systemLoop[0..^3]
  let componentNames = systemLoop[^2][1..^1]
  let forBody = systemLoop[^1]

  result.add ident"entity"
  result.add ident"getQueriedEntities".newCall(ident"command")

  for (ident, ty) in zip(componentIdents, componentNames):
    if ty.kind == nnkVarTy:
      let typeName = ty[0]
      forBody.insert 0, quote do:
        var `ident` = entity.get(`typeName`)

      forBody.add quote do:
        entity.attach(`ident`)

    else:
      let typeName = ty
      forBody.insert 0, quote do:
        let `ident` = entity.get(`typeName`)

  result.add forBody

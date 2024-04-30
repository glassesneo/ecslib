import
  std/macros,
  ./type_definition

macro iterate*(query: Query, signature: untyped, body: untyped): untyped =
  ## q1.iterate((pos, vel) in (Pos, Vel)):
  ##   pos.x = vel.x * dt
  ##   pos.y = vel.y * dt
  let (variables, op, types) = unpackInfix(signature)
  if op != "in":
    error "Invalid syntax", signature[0]

  let variableDefs = newStmtList()
  for i in 0..<variables.len:
    let
      name = variables[i]
      T = types[i]

    variableDefs.add quote do:
      let `name` = entity.get(`T`)

  result = newStmtList(
    nnkForStmt.newTree(
      ident"entity",
      query.newDotExpr(ident"queriedEntities"),
      quote do:
    `variableDefs`
    `body`
  )
  )

proc toStrLitQuery(queryElement: NimNode): NimNode {.compileTime.} =
  result = queryElement.kind.newTree()
  for i in 0..<queryElement.len:
    result.add queryElement[i].toStrLit()

proc readNode(node: NimNode, world: NimNode): NimNode {.compileTime.} =
  result = newCall(world.newDotExpr(ident"createQuery"))
  for query in node[1]:
    query.expectKind(nnkAsgn)
    query[0].expectKind(nnkIdent)

    case query[0].strVal
    of "All":
      result.add query[1][1].toStrLitQuery().prefix"@"
    of "Any":
      result.add query[1][1].toStrLitQuery().prefix"@"
    of "None":
      result.add query[1][1].toStrLitQuery().prefix"@"
    else:
      error "Invalid query", query[0]

macro defineQuery*(world: World, body: untyped): untyped =
  body.expectKind(nnkStmtList)

  result = newStmtList()

  for node in body:
    node.expectKind(nnkCall)
    node[0].expectKind(nnkIdent)
    node[1].expectKind(nnkStmtlist)
    let queryName = node[0]
    let queryInstance = readNode(node, world)

    result.add quote do:
      let `queryName` = `queryInstance`

macro system*(theProc: untyped): untyped =
  theProc.expectKind(nnkProcDef)
  result = theProc

  let systemBody = newStmtList()

  for node in theProc.body:
    case node.kind
    of nnkUsingStmt:
      for identDef in node:
        let varName = identDef[0]
        let queryName = identDef[2]
        systemBody.add quote do:
          let `varName` = `queryName`

    else:
      systemBody.add node

  result.body = systemBody

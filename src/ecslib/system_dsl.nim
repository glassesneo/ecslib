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


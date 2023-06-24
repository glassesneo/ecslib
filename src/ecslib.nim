import
  std/macros,
  std/tables,
  ecslib/[system_dsl, type_definition]

macro system*(procDef: untyped{nkProcDef}): untyped =
  let systemName = procDef.name
  let returnerName = systemName
  let args = nnkFormalParams.newNimNode().add(newEmptyNode())
  var conditions: seq[ComponentCondition]

  for identDef in procDef[3][1..^1]:
    if identDef.len > 3:
      error "multiple arguments of the same type are not allowed"

    if identDef[1].kind == nnkBracketExpr:
      let typeNode = nnkBracketExpr.newTree(
        ident"Component",
        identDef[1][0]
      )

      let shapedIdentDef = newIdentDefs(
        identDef[0],
        typeNode
      )

      args.add(shapedIdentDef)

      conditions.add parseTypeNode(identDef[1])

    else:
      let typeNode = nnkBracketExpr.newTree(
        ident"Component",
        identDef[1]
      )

      let shapedIdentDef = newIdentDefs(
        identDef[0],
        typeNode
      )

      args.add(shapedIdentDef)

  let systemType = nnkProcTy.newTree(args, newEmptyNode())

  result = quote do:
    proc `returnerName`*: System[`systemType`] =
      result = System[`systemType`].new()

  for condition in conditions:
    let
      typeNameLit = newStrLitNode(condition.typeNameNode.strVal)
      conditionNode = condition.conditionNode
    result.body.add quote do:
      result.conditions[`typeNameLit`] = `conditionNode`

  let updateProc = nnkLambda.newTree(
    newEmptyNode(),
    newEmptyNode(),
    newEmptyNode(),
    nnkFormalParams.newTree(),
    newEmptyNode(),
    newEmptyNode(),
    newStmtList()
  )
  updateProc.params = args
  updateProc.body = procDef.body

  result.body.add quote do:
    result.update = `updateProc`

export
  ecslib.type_definition,
  ecslib.system_dsl

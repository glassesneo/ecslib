import
  std/macros,
  std/sugar,
  ./type_definition

type
  ComponentCondition* = tuple
    typeNameNode, conditionNode: NimNode

proc parseCondition(node: NimNode): NimNode =
  if node.kind == nnkCall and node.len == 2:
    let arg = node[1]
    case node[0].strVal
    of "with":
      result = quote do:
        e.has(`arg`)
    of "without":
      result = quote do:
        not e.has(`arg`)
    else:
      error "Unsupported syntax", node
    return

  if node.kind == nnkInfix:
    let
      (left, op, right) = node.unpackInfix
      leftCondition = left.parseCondition()
      rightCondition = right.parseCondition()

    case op
    of "and":
      result = quote do:
        `leftCondition` and `rightCondition`

    of "or":
      result = quote do:
        `leftCondition` or `rightCondition`
    else:
      error "Unsupported syntax", node
    return

  if node.kind == nnkPar:
    return node[0].parseCondition()

  error "Unsupported syntax", node

proc parseTypeNode*(node: NimNode): ComponentCondition =
  node.expectKind nnkBracketExpr

  result.typeNameNode = node[0]

  let condition = node[1].parseCondition()

  result.conditionNode = quote do:
    (e: Entity) => `condition`

macro runSystem*(world, returner: typed): untyped =
  let impl = returner.getImpl()
  let returnerName = impl[0]
  let systemName = ident "system"

  result = nnkBlockStmt.newTree(
    newEmptyNode(),
    newStmtList()
  )

  result[1] = quote do:
    let `systemName` = `returnerName`()
    system.update()

  for identDef in impl[3][0][2][0][1..^1]:
    let typeIdent = identDef[1][1]
    result[1][1].add quote do:
      `world`.componentOf(`typeIdent`).match(`systemName`)

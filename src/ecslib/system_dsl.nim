import
  std/macros,
  ./type_definition

type
  ComponentQuery* = tuple
    typeName, condition: NimNode

proc parseCondition(node: NimNode): NimNode =
  if node.kind == nnkCall and node.len == 2:
    let arg = node[1]
    case node[0].strVal
    of "with":
      result = quote do:
        entity.has(`arg`)
    of "without":
      result = quote do:
        not entity.has(`arg`)
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

proc parseTypeNode*(node: NimNode): ComponentQuery =
  node.expectKind nnkBracketExpr

  result.typeName = node[0]

  let condition = node[1].parseCondition()

  result.condition = newStmtList(condition)

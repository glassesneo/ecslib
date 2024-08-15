import
  std/[
    algorithm,
    macros,
    macrocache,
    sequtils,
    strutils
  ],
  ecs_types

type
  ComponentQueryType = enum
    QAll = "All"
    QAny = "Any"
    QNone = "None"

template genSystemProc(name, commands, entities, process) =
  proc name(
      commands: Commands,
      entities: seq[Entity]
  ) =
    process

macro system*(theProc: untyped): untyped =
  let queryParams = theProc.params

  case queryParams[0].kind
  of nnkEmpty:
    discard
  of nnkIdent:
    if not queryParams[0].eqIdent "void":
      error "System can't return a value", queryParams[0]
  else:
    error "System can't return a value", queryParams[0]

  let
    entitiesName = ident"entities"
    commandsName = ident"commands"
    specNode = nnkTupleConstr.newTree(
      newColonExpr(ident"qAll", quote do: @[]),
      newColonExpr(ident"qAny", quote do: @[]),
      newColonExpr(ident"qNone", quote do: @[]),
      newColonExpr(ident"events", quote do: @[])
    )

  var
    resourceAssignmentList: seq[NimNode]
    eventAssignmentList: seq[NimNode]
    eventCheckList: seq[NimNode]

  for query in queryParams[1..^1]:
    case query[1].kind
    of nnkBracket:
      if query[1].len != 0:
        let queryType = parseEnum[ComponentQueryType](query[0].strVal)

        let targetsLit = query[1].mapIt(it.strVal).newLit()

        case queryType
        of QAll:
          specNode[0] = newColonExpr(ident"qAll", targetsLit)
        of QAny:
          specNode[1] = newColonExpr(ident"qAny", targetsLit)
        of QNone:
          specNode[2] = newColonExpr(ident"qNone", targetsLit)

    of nnkBracketExpr:
      if query[1].len != 2:
        error "Unsupported syntax", query[1][0]

      let instance = query[0]
      let queryType = query[1][1]

      case query[1][0].strVal
      of "Resource":
        resourceAssignmentList.add quote do:
          let `instance` = `commandsName`.getResource(`queryType`)

      of "Event":
        specNode[3][1][1].add queryType.strVal.newLit()
        eventAssignmentList.add quote do:
          let `instance` = `commandsName`.receiveEvent(`queryType`)
        eventCheckList.add quote do:
          `instance`.checkReferenceCount()

    else:
      error "Unsupported syntax", query[1]

  let processNode = theProc.body

  for assignment in resourceAssignmentList.reversed:
    processNode.insert 0, assignment

  for assignment in eventAssignmentList.reversed:
    processNode.insert 0, assignment

  for statement in eventCheckList:
    processNode.add statement

  let systemName = theProc[0]

  result = getAst genSystemProc(systemName, commandsName, entitiesName, processNode)

  let systemNameString = theProc.name.strVal

  specTable[systemNameString] = specNode
  systemTable[systemNameString] = result

macro each*(loop: ForLoopStmt): untyped =
  let
    instanceList = loop[0..^3]
    entities = loop[^2][1]
    componentList = loop[^2][2][0..^1]
    body = newStmtList(loop[^1])

  if instanceList.len != componentList.len:
    error "The length of the variables and components doesn't match", loop

  let createInstances = newStmtList()

  let entityName = ident"entity"

  for i in 0..<instanceList.len:
    let
      instance = instanceList[i]
      component = componentList[i]

    createInstances.add quote do:
      let `instance` = `entityName`.get(`component`)

  result = quote do:
    for `entityName` in `entities`:
      `createInstances`
      `body`


import
  std/[
    algorithm,
    macros,
    macrocache,
    sequtils,
    strutils,
    tables
  ],
  ecs_types

type
  ComponentQueryType = enum
    QAll = "All"
    QAny = "Any"
    QNone = "None"

template genSystemProc(name, commands, queryPack, process) =
  proc name(
      commands: Commands,
      queryPack: Table[string, seq[Entity]]
  ) =
    process

macro system*(theProc: untyped): untyped =
  let queryParams = theProc.params

  let querySpecMap: array[ComponentQueryType, NimNode] = [
    ident"qAll",
    ident"qAny",
    ident"qNone"
  ]

  case queryParams[0].kind
  of nnkEmpty:
    discard
  of nnkIdent:
    if not queryParams[0].eqIdent "void":
      error "System can't return a value", queryParams[0]
  else:
    error "System can't return a value", queryParams[0]

  let
    queryPackName = ident"queryPack"
    commandsName = ident"commands"

  var
    queryAssignmentList: seq[NimNode]
    resourceAssignmentList: seq[NimNode]
    eventAssignmentList: seq[NimNode]
    eventCheckList: seq[NimNode]
    specNode = quote do:
      (queryTable: initTable[string, Query](), eventList: newSeq[string]())

    isEventListEmpty = true

  for query in queryParams[1..^1]:
    let queryName = query[0]
    case query[1].kind
    of nnkBracket:
      let queryNode = nnkTupleConstr.newTree(
        newColonExpr(ident"qAll", quote do: newSeq[string]()),
        newColonExpr(ident"qAny", quote do: newSeq[string]()),
        newColonExpr(ident"qNone", quote do: newSeq[string]()),
      )

      if query[1].len notin 1..3:
        error "Unsupported syntax", query[1][0]

      for node in query[1]:
        let queryType = parseEnum[ComponentQueryType](node[0].strVal)

        let targetsLit = node[1..^1].mapIt(it.strVal).newLit()

        case queryType
        of QAll:
          queryNode[0] = newColonExpr(querySpecMap[queryType], targetsLit)
        of QAny:
          queryNode[1] = newColonExpr(querySpecMap[queryType], targetsLit)
        of QNone:
          queryNode[2] = newColonExpr(querySpecMap[queryType], targetsLit)

      let queryNameLit = queryName.strVal.newLit()

      let queryColonExpr = newColonExpr(queryNameLit, queryNode)

      if specNode[0][1][0][1].eqIdent"initTable":
        specNode[0][1][0] = newDotExpr(
          nnkTableConstr.newTree(
            queryColonExpr
          ),
          ident"toTable"
        )
      else:
        specNode[0][1][0][0].add newColonExpr(queryNameLit, queryNode)

      queryAssignmentList.add quote do:
        let `queryName` {.used.} = queryPack[`queryNameLit`]

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
        let eventNameLit = queryType.strVal.newLit()
        if isEventListEmpty:
          isEventListEmpty = false
          specNode[1][1] = quote do: @[`eventNameLit`]
        else:
          specNode[1][1][1].add queryType.strVal.newLit()
        eventAssignmentList.add quote do:
          let `instance` = `commandsName`.receiveEvent(`queryType`)
        eventCheckList.add quote do:
          `instance`.checkReferenceCount()

    else:
      error "Unsupported syntax", query[1]

  let processNode = theProc.body

  for assignment in queryAssignmentList.reversed:
    processNode.insert 0, assignment

  for assignment in resourceAssignmentList.reversed:
    processNode.insert 0, assignment

  for assignment in eventAssignmentList.reversed:
    processNode.insert 0, assignment

  for statement in eventCheckList:
    processNode.add statement

  let systemName = theProc[0]

  result = getAst genSystemProc(systemName, commandsName, queryPackName, processNode)

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

  let indexName = ident (entities.strVal & "index")

  for i in 0..<instanceList.len:
    let
      instance = instanceList[i]
      component = componentList[i]

    createInstances.add quote do:
      let `instance` = `entities`[`indexName`].get(`component`)

  result = quote do:
    for `indexName` in 0..<`entities`.len():
      `createInstances`
      `body`


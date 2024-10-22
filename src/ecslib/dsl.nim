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
        let `queryName` = queryPack[`queryNameLit`]

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

  let deferNode = nnkDefer.newTree(newStmtList())
  for statement in eventCheckList:
    deferNode[0].add statement
  processNode.insert 0, deferNode

  for assignment in eventAssignmentList.reversed:
    processNode.insert 0, assignment

  let systemName = theProc[0]

  result = getAst genSystemProc(systemName, commandsName, queryPackName, processNode)

  let systemNameString = theProc.name.strVal

  specTable[systemNameString] = specNode
  systemTable[systemNameString] = result

macro combination*(query: seq[Entity]; args, body: untyped): untyped =
  args.expectKind(nnkBracket)

  let
    v1 = args[0][0]
    c1 = args[0][1]
    v2 = args[1][0]
    c2 = args[1][1]

  let
    index1 = ident(query.strVal & "Index1")
    index2 = ident(query.strVal & "Index2")
    length = ident(query.strVal & "Length")

  result = quote do:
    block:
      let `length` = `query`.len()
      for `index1` in 0..<`length`:
        for `index2` in 0..<`length`:
          block:
            let `v1` = `query`[`index1`].get(`c1`)
            let `v2` = `query`[`index2`].get(`c2`)
            `body`


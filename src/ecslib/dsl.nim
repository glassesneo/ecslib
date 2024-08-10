import
  std/[
    algorithm,
    macros,
    sequtils,
    setutils,
    strutils
  ]

type
  ComponentQueryType = enum
    QAll = "All"
    QAny = "Any"
    QNone = "None"

proc entityIdSetNode(world, T: NimNode): NimNode {.compileTime.} =
  return quote do: `world`.getOrEmpty(`T`)

proc fullSetNode(world: NimNode): NimNode {.compileTime.} =
  result = quote do:
    `world`.fullEntityIdSet

proc queryIntersection(
    world: NimNode,
    targets: seq[NimNode]
): NimNode {.compileTime.} =
  result = targets.mapIt(world.entityIdSetNode(it)).foldl(
    infix(a, "*", b)
  )

proc queryUnion(
    world: NimNode,
    targets: seq[NimNode]
): NimNode {.compileTime.} =
  result = targets.mapIt(world.entityIdSetNode(it)).foldl(
    infix(a, "+", b)
  )

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
    worldName = ident"world"

  var
    queryArray: array[ComponentQueryType, NimNode] = [
      fullSetNode(worldName),
      fullSetNode(worldName),
      nnkCurly.newNimNode()
    ]
    resourceAssignmentList: seq[NimNode]
    eventAssignmentList: seq[NimNode]

  for query in queryParams[1..^1]:
    case query[1].kind
    of nnkBracket:
      if query[1].len != 0:
        let queryType = parseEnum[ComponentQueryType](query[0].strVal)
        if query[1].len == 1:
          queryArray[queryType] = entityIdSetNode(worldName, query[1][0])
          continue

        let targets = query[1][0..^1]
        case queryType
        of QAll:
          queryArray[queryType] = queryIntersection(worldName, targets)
        of QAny, QNone:
          queryArray[queryType] = queryUnion(worldName, targets)

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
        eventAssignmentList.add quote do:
          let `instance` = `commandsName`.receiveEvent(`queryType`)

    else:
      error "Unsupported syntax", query[1]

  let queriesNode = block:
    let
      qAll = queryArray[QAll]
      qAny = queryArray[QAny]
      qNone = queryArray[QNone]

    quote do:
      `qAll` * `qAny` - `qNone`

  let processNode = theProc.body

  for assignment in resourceAssignmentList.reversed:
    processNode.insert 0, assignment

  for assignment in eventAssignmentList.reversed:
    processNode.insert 0, assignment

  let systemName = theProc[0]

  result = quote do:
    let `systemName` = System.new(
      query = proc(
          `worldName`: World
      ): set[EntityId] = `queriesNode`,
      process = proc(
        `entitiesName`: seq[Entity];
        `commandsName`: Commands
      ) = `processNode`,
    )

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


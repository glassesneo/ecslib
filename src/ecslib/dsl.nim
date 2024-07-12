import
  std/macros,
  std/sequtils

type
  Query = ref object
    procName: string
    targets: seq[string]

proc new(
    _: type Query;
    procName: string;
    target: seq[string]
): Query {.compileTime.} =
  return Query(
    procName: procName,
    targets: target
  )

proc toQueryProc(query: Query; entityName: NimNode): NimNode {.compileTime.} =
  let procName = query.procName.ident
  let targets = query.targets.newLit()
  result = quote do:
    `entityName`.`procName`(`targets`)

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

  var queryList: seq[Query]

  for query in queryParams[1..^1]:
    var targets: seq[string]
    for t in query[1]:
      targets.add t.strVal
    if targets.len != 0:
      case query[0].strVal
      of "All":
        queryList.add Query.new("hasAll", targets)

      of "Any":
        queryList.add Query.new("hasAny", targets)

      of "None":
        queryList.add Query.new("hasNone", targets)

      else:
        error "Unsupported query", query[0]

  let
    entityName = ident"entity"
    entitiesName = ident"entities"
    commandsName = ident"commands"

  let queriesNode = block:
    if queryList.len == 0:
      newLit(true)
    else:
      queryList
        .map(proc(q: Query): NimNode = q.toQueryProc(ident"entity"))
        .foldl(infix(a, "and", b))

  let processNode = theProc.body

  let systemName = theProc.name

  result = quote do:
    let `systemName` = System.new(
      query = proc(
          `entityName`: Entity
      ): bool {.raises: [KeyError], gcsafe.} = `queriesNode`,
      process = proc(
        `entitiesName`: seq[Entity];
        `commandsName`: Commands
      ) {.raises: [Exception], gcsafe.} = `processNode`,
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


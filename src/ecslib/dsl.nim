import
  std/[algorithm, macros, sequtils]

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

proc mapToQueryProcName(queryNode: NimNode): string =
  case queryNode[0].strVal
  of "All":
    return "hasAll"
  of "Any":
    return "hasAny"
  of "None":
    return "hasNone"
  else:
    error "Unsupported query", queryNode[0]

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
    entityName = ident"entity"
    entitiesName = ident"entities"
    commandsName = ident"commands"

  var
    queryList: seq[Query]
    resourceAssignmentList: seq[NimNode]

  for query in queryParams[1..^1]:
    case query[1].kind
    of nnkBracket:
      var targets: seq[string]
      for t in query[1]:
        targets.add t.strVal
      if targets.len != 0:
        let procName = mapToQueryProcName(query)
        queryList.add Query.new(procName, targets)

    of nnkBracketExpr:
      if not (query[1][0].eqIdent"Resource" and query[1].len == 2):
        error "Unsupported syntax", query[1][0]

      let instance = query[0]
      let resource = query[1][1]

      resourceAssignmentList.add quote do:
        let `instance` = `commandsName`.getResource(`resource`)

    else:
      error "Unsupported syntax", query[1]

  let queriesNode = block:
    if queryList.len == 0:
      newLit(true)
    else:
      queryList
        .map(proc(q: Query): NimNode = q.toQueryProc(ident"entity"))
        .foldl(infix(a, "and", b))

  let processNode = theProc.body

  for assignment in resourceAssignmentList.reversed:
    processNode.insert 0, assignment

  let systemName = theProc[0]

  result = quote do:
    let `systemName` = System.new(
      query = proc(
          `entityName`: Entity
      ): bool = `queriesNode`,
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


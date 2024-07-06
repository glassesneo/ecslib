import
  std/macros,
  std/sequtils,
  ./type_definition

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

proc newAND(a, b: NimNode): NimNode {.compileTime.} =
  result = infix(a, "and", b)

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

  let entityName = ident"entity"

  let entitiesName = ident"entities"

  let queriesNode = queryList.mapIt(it.toQueryProc(ident"entity")).foldl(newAND(a, b))

  let processNode = theProc.body

  let systemName = theProc.name

  result = quote do:
    let `systemName` = System.new(
      query = proc(`entityName`: Entity): bool = `queriesNode`,
      process = proc(`entitiesName`: seq[Entity]) = `processNode`,
    )


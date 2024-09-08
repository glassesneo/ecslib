discard """
  action: "run"
"""

import
  ../src/ecslib

type
  A = ref object

  B = ref object

  C = ref object

proc callA(AQuery: [All[A]]) {.system.} =
  echo "Call A"

proc callB(AQuery: [All[B]]) {.system.} =
  echo "Call B"

proc callC(AQuery: [All[C]]) {.system.} =
  echo "Call C"

let world = World.new()

world.arrangeStageList([
  "beforeUpdate",
  "update",
  "afterUpdate"
])

world.registerSystems(callC)
world.registerSystems("beforeUpdate", callB)
world.registerSystems("afterUpdate", callA)

world.runStartupSystems()
world.runSystems()
world.runTerminateSystems()


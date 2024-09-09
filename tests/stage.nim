discard """
  action: "run"
"""

import
  ../src/ecslib,
  ./systems

proc echo1 {.system.} =
  echo 1

proc echo2 {.system.} =
  echo 2

proc echo3 {.system.} =
  echo 3

proc echo4 {.system.} =
  echo 4

proc echo5 {.system.} =
  echo 5

let world = World.new()

world.arrangeStageList([
  "beforeUpdate",
  "update",
  "afterUpdate"
])

world.registerSystems(echo2, echo3)
world.registerSystemsAt("afterUpdate", echo4, echo5)
world.registerSystemsAt("beforeUpdate", echo1)
world.registerSystems(doNothing)

world.runStartupSystems()
world.runSystems()
world.runTerminateSystems()


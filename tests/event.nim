discard """
  action: "run"
"""

import
  std/tables,
  ../src/ecslib

type
  SomeEvent = ref object
    id: int

var count = 0

proc sendEvent* {.system.} =
  commands.dispatchEvent(SomeEvent(id: count))
  count += 1

proc readEvent*(eventQueue: Event[SomeEvent]) {.system.} =
  for e in eventQueue:
    echo e.id

let world = World.new()

world.registerSystems(sendEvent, readEvent)
world.addEvent(SomeEvent)


for i in 0..<50:
  world.runSystems()


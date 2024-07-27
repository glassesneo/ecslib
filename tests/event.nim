discard """
  action: "run"
"""

import
  ../src/ecslib

type
  SomeEvent = ref object
    id: int

proc readEvent*(eventQueue: Event[SomeEvent]) {.system.} =
  for e in eventQueue:
    echo e.id

let world = World.new()

world.dispatchEvent(SomeEvent(id: 0))
world.dispatchEvent(SomeEvent(id: 1))
world.dispatchEvent(SomeEvent(id: 2))

world.registerSystems(readEvent)
world.runSystems()


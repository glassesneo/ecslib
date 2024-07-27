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

world.registerSystems(readEvent)
world.addEvent(SomeEvent)

world.dispatchEvent(SomeEvent(id: 0))
world.dispatchEvent(SomeEvent(id: 1))
world.dispatchEvent(SomeEvent(id: 2))
world.dispatchEvent(SomeEvent(id: 3))

world.runSystems()


discard """
  action: "run"
"""

import
  ../src/ecslib

type
  Window = ref object
    title: string
    width, height: int

let world = World.new()

proc outputWindowState {.system.} =
  let window = commands.getResource(Window)
  echo "title: ", window.title
  echo "width: ", window.width
  echo "height: ", window.height

world.addResource(Window(title: "original", width: 640, height: 480))
world.registerSystems(outputWindowState)

world.runSystems()

world.updateResource(Window(title: "changed", width: 500))

world.runSystems()


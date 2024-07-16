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

proc settings {.system.} =
  commands.updateResource(Window(title: "changed", width: 500))

proc outputWindowState {.system.} =
  let window = commands.getResource(Window)
  echo "title: ", window.title
  echo "width: ", window.width
  echo "height: ", window.height

world.addResource(Window(title: "original", width: 640, height: 480))
world.registerStartupSystems(settings)
world.registerSystems(outputWindowState)

world.runStartupSystems()
world.runSystems()

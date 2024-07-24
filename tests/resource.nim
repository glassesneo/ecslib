discard """
  action: "run"
"""

import
  ../src/ecslib

type
  Window = ref object
    title: string
    width, height: int

  Options = ref object
    developerMode: bool
    outputState: bool

let world = World.new()

proc settings(options: Resource[Options]) {.system.} =
  if options.developerMode:
    commands.updateResource(Window(title: "dev mode", width: 500))

proc outputWindowState(
    options: Resource[Options],
    window: Resource[Window]
) {.system.} =
  if options.outputState:
    echo "title: ", window.title
    echo "width: ", window.width
    echo "height: ", window.height

world.addResource(Window(title: "original", width: 640, height: 480))
world.addResource(Options(developerMode: true, outputState: true))
world.registerStartupSystems(settings)
world.registerSystems(outputWindowState)

world.runStartupSystems()
world.runSystems()

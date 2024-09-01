discard """
  action: "run"
"""

import std/unittest

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

world.addResource(Window(title: "original", width: 640, height: 480))
world.addResource(Options(developerMode: true, outputState: true))

world.updateResource(Window(title: "changed"))

check world.hasResource(Window)
check world.getResource(Window).title == "changed"

check world.hasResource(Options)
world.deleteResource(Options)
check not world.hasResource(Options)


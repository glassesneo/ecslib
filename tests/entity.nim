discard """
  action: "run"
"""

import
  ../src/ecslib

let world = World.new()

let entity = world.create()

entity.delete()

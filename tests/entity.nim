discard """
  action: "run"
"""

import
  std/unittest,
  ../src/ecslib

let world = World.new()

let entity = world.create()

check entity == world.getEntity(entity.id)

entity.delete()


discard """
  action: "run"
"""

import std/unittest

import
  ../src/ecslib

let world = World.new()

let entity = world.create()

check $entity == "Entity(id: 1)"

check entity == world.getEntity(entity.id)

entity.delete()

check not entity.isValid()


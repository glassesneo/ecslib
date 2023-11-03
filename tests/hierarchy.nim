discard """
  action: "run"
"""

import
  std/unittest,
  ../src/ecslib

type
  Position = ref object
    x, y: int

  Transform = object
    absolute, local: Position

proc new(_: type Transform, absolute: Position): Transform =
  result = Transform(absolute: absolute)

proc setLocalPosition(tf: var Transform, parentPosition: Position) =
  tf.local = Position(
    x: tf.absolute.x - parentPosition.x,
    y: tf.absolute.y - parentPosition.y
  )

let world = World.new()

let parentEntity = world.create().attach(Transform.new(Position(x: 0, y: 0)))

var childTf1 = Transform.new(Position(x: 5, y: 5))
childTf1.setLocalPosition(parentEntity.get(Transform).absolute)

let childEntity1 = world.create().attach(childTf1)

parentEntity.addChildren(childEntity1)

var childTf2 = Transform.new(Position(x: 3, y: 3))
childTf2.setLocalPosition(parentEntity.get(Transform).absolute)

let childEntity2 {.used.} = world.create().registerParent(parentEntity).attach(childTf2)

proc move(all = [var Transform, Parent]) {.system.} =
  for tf in each(var Transform):
    tf.absolute.x += 5
    tf.absolute.y += 5

proc calculateLocalPosition(all = [var Transform, Child]) {.system.} =
  for tf, child in each(var Transform, Child):
    let parentEntity = child.parent
    let parentTf = parentEntity.get(Transform)
    tf.absolute.x = tf.local.x + parentTf.absolute.x
    tf.absolute.y = tf.local.y + parentTf.absolute.y

world.addSystem(move)
world.addSystem(calculateLocalPosition)

let parentTransform = parentEntity.get(Transform)


for i in 0..<10:
  world.runSystems()

check parentTransform.absolute.x == 50
check parentTransform.absolute.y == 50

check childTf1.absolute.x == 55
check childTf1.absolute.y == 55

check childTf2.absolute.x == 53
check childTf2.absolute.y == 53

parentEntity.removeChildren(childEntity1)

childEntity2.removeParent()

discard """
  action: "run"
"""

import
  std/strformat,
  ../src/ecslib

type
  Position = ref object
    x, y: int

  Transform = ref object
    absolute, local: Position

proc new(_: type Transform, absolute: Position): Transform =
  result = Transform(absolute: absolute)

proc setLocalPosition(tf: Transform, parentPosition: Position) =
  tf.local = Position(
    x: tf.absolute.x - parentPosition.x,
    y: tf.absolute.y - parentPosition.y
  )

let world = World.new()

let parentEntity = world.create().attach(Transform.new(Position(x: 0, y: 0)))

let childTf1 = Transform.new(Position(x: 5, y: 5))
childTf1.setLocalPosition(parentEntity.get(Transform).absolute)

let childEntity1 = world.create().attach(childTf1)

parentEntity.withChildren(childEntity1)

let childTf2 = Transform.new(Position(x: 3, y: 3))
childTf2.setLocalPosition(parentEntity.get(Transform).absolute)

let childEntity2 {.used.} = world.create().withParent(parentEntity).attach(childTf2)

proc move(all = [Transform, Parent]) {.system.} =
  for tf in each(Transform):
    tf.absolute.x += 5
    tf.absolute.y += 5

proc calculateLocalPosition(all = [Transform, Child]) {.system.} =
  for tf, child in each(Transform, Child):
    let parentEntity = child.parent
    let parentTf = parentEntity.get(Transform)
    tf.absolute.x = tf.local.x + parentTf.absolute.x
    tf.absolute.y = tf.local.y + parentTf.absolute.y

world.addSystem(move)
world.addSystem(calculateLocalPosition)

let parentTransform = parentEntity.get(Transform)

echo "==============="
echo fmt"parent position: (x: {parentTransform.absolute.x}, y: {parentTransform.absolute.y})"
echo fmt"child1 position: (x: {childTf1.absolute.x}, y: {childTf1.absolute.y})"
echo fmt"child2 position: (x: {childTf2.absolute.x}, y: {childTf2.absolute.y})"

for i in 0..<10:
  world.runSystems()

echo "==============="
echo fmt"parent position: (x: {parentTransform.absolute.x}, y: {parentTransform.absolute.y})"
echo fmt"child1 position: (x: {childTf1.absolute.x}, y: {childTf1.absolute.y})"
echo fmt"child2 position: (x: {childTf2.absolute.x}, y: {childTf2.absolute.y})"

parentEntity.removeChildren(childEntity1)

childEntity2.removeParent()

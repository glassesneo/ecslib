import
  ../src/ecslib,
  ./systems

let world = World.new()

world.registerSystems(doNothing)


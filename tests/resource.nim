discard """
  action: "run"
"""

import
  ../src/ecslib

type
  Language* = enum
    Japanese
    English
  UserSettings = ref object
    language: Language
    soundVolume: range[0..100]

  SoundManager = ref object

proc play(sound: SoundManager, soundVolue: range[0..100]) =
  echo "playing sound at volume ", soundVolue

let world = World.new()

world.addResource(
  UserSettings(language: Japanese, soundVolume: 50)
)

let speaker = world.create().attach(SoundManager())

proc playSound(All: [SoundManager]) {.system.} =
  let settings = command.getResource(UserSettings)
  for sound in each(entities, [SoundManager]):
    sound.play(settings.soundVolume)

proc turnDownSoundVolume(All: [SoundManager]) {.system.} =
  let settings = command.getResource(UserSettings)
  settings.soundVolume -= 5

world.registerSystem(playSound)
world.registerSystem(turnDownSoundVolume)

for i in 0..<10:
  world.runSystems()

world.deleteResource(UserSettings)


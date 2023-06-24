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

let world = World.new()

world.addResource(
  UserSettings(language: Japanese, soundVolume: 50)
)

echo world.getResource(UserSettings).soundVolume

world.deleteResource(UserSettings)

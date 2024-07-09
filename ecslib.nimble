# Package

version = "0.2.0"
author = "glassesneo"
description = "A nimble package for Entity Component System"
license = "MIT"
srcDir = "src"


# Dependencies

requires "nim >= 2.0.4"

task tests, "Run all tests":
  exec "testament p 'tests/*nim'"

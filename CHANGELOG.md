# Change Log
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]
### Added
- `hasResource()` for `World` and `Commands` to get if a resource is added or not
- `getEntity()` for `World` and `Commands` to get Entity by its id
- `Resource[T]` argument for systems to specify the resources used in the system

### Fixed
- Fixed an issue on exporting systems
- Fixed the order of Terminate systems

## [0.3.2] - 2024-07-13
### Changed
- Stopped using `{.raises.}` for anonymous systems

## [0.3.1] - 2024-07-13
### Added
- Adopt Nim's effect system

## [0.3.0] - 2024-07-12
### Added
- `create()`, `addResource()`, `registerSystems()` for `Commands`
- Terminate systems called when the game quits

### Changed
- Rename `Command` to `Commands`

## [0.2.0] - 2024-07-10
### Added
- `registerSystems()`, `registerStartupSystems()` to register systems

### Removed
- Remove `registerSystem()`, `registerStartupSystem()`

### Fixed
- Fix a compiling issue in `system` with no arguments

## 0.1.0 - 2024-07-08

[Unreleased]: https://github.com/glassesneo/ecslib/compare/0.3.1...HEAD
[0.3.1]: https://github.com/glassesneo/ecslib/compare/0.3.0...0.3.1
[0.3.0]: https://github.com/glassesneo/ecslib/compare/0.2.0...0.3.0
[0.2.0]: https://github.com/glassesneo/ecslib/compare/0.1.0...0.2.0

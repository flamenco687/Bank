## [1.0.6-beta] - 2021-11-24

### Added

- Added some primitive type annotations to most function arguments

### Changed
- `AutosaveKeys` and `RefreshLocks` are now two separated functions, ran in different threads that only execute once every x time instead of
being connected to `RunService.Heartbeat` checking the last tick.
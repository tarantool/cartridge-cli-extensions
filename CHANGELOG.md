# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.1.1] - 2020-03-24

### Fixed

- All returned maps have `{__serialize = 'map'}` set.
  Cartridge CLI calls ExecTyped using connectors. Such calls expects map values,
  but Lua empty tables are serialized as arrays by default.

## [1.1.0] - 2020-12-28

### Added

- Performing `box.session.push` on `print` when admin function is called

## [1.0.0] - 2020-10-23

### Added

- Admin extension for  `cartridge admin` command

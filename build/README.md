# Builds
This directory contains reusable build components encompassing common CI/CD and local build tasks.

## Contents
- `Makefile.*` files serving as importable Makefile modules into external Makefiles
  - `Makefile.Common` - common functionality, **required prerequisite**, as it prescribes variables utilized in other modules
  - `Makefile.Licenses` - functionality for licenses checks
  - `Makefile.Release` - functionality for common GitHub and other releasing tasks
- `scripts/` folder containing executable scripts that are utilized by Makefile commands, but can be also executed directly

## How to reference
The Makefiles can be referenced in projects in following way:
- add this repository as Git submodule, clone ie. to directory `submodules/solarwinds-otel-collector-core`
- create Makefile in the project
- on the top of the Makefile add following section:
```
include submodules/solarwinds-otel-collector-core/build/Makefile.Common     # Required for all Makefile modules
include submodules/solarwinds-otel-collector-core/build/Makefile.Licenses   # Optional import of Licenses functionality
include submodules/solarwinds-otel-collector-core/build/Makefile.Release    # Optional import of Release functionality
```
These steps make sure the tasks contained within included Makefile modules will be available when running `make` command in the project.

## How to develop
When adding new Makefile functionality:
- consider into which file the extension should be done based on the functionality it is extending
- when no file is not suitable, create new one - ideally to reflect as general area as possible to allow further extensions
- extend [Contents](#contents) section with brief description of the module

> [!NOTE]  
> When adding new bash script file, don't forget to add execute permission `chmod +x {script name}`

# magic_makefile
A magic Makefile that automatically
- detects C++ source files in the current directory (with a .cc extension) and subdirectories
- detects binaries to be compiled from the `main/` folder
- detects tests that end with `_test.cc`

and compiles all binaries (in the `bin` output folder) and tests (linking in `gtest` and `gmock`).

Header and object dependencies are automatically tracked, for faster recompilations.

Running `make test` will run all the tests.

It's necessary to write a config.mk file, defining compilation flags and, if needed, extra object dependencies (by default, dependencies are detected through header inclusion).

Requires `bash`, `tar` and `python`.

# Test of CMake + ACE+TAO

## Build

`cd` into the checkout and run:

* `make -f Makefile.setup`
* In `ACE_wrappers/TAO/TAO_IDL/CMakeLists.txt`, comment out the 8 VIS lines (`TAO_IDL_BE_VIS_A` through `TAO_IDL_BE_VIS_V`)
* `mkdir build`
* `cd build && cmake ..`
* `cmake --build .`

### Build Dependencies

* GNU `make`, which calls
  * `curl`
  * `unzip`
  * `rm`
  * `git`
  * `perl`
* `cmake`


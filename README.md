# Test of CMake + ACE+TAO

## Build

`cd` into the checkout and run:

* `make -f Makefile.setup`
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


## Build and Install Instructions
---

### Prerequisites
A supported Fortran compiler (see table below).  Other versions may work, in particular if close to the versions listed below.

| Compiler vendor | Supported (tested) versions                                |
|-----------------|------------------------------------------------------------|
| Intel           | 18.0.3.222 and above                                       |
| GNU             | 10.3.0 and above                                           |

Third-party libraries (TPL) compiled with the same compiler (where applicable).

| Library         | Supported (tested) versions                                |
|-----------------|------------------------------------------------------------|
| CMake           | 3.20.1 and above                                           |
| NetCDF-Fortran  | 4.5.2 and above                                            |

GSI NetCDF Diagnostic (`ncdiag`) library compiled with the same compiler.

NCEP Libraries (NCEPLibs) compiled with the same compiler (where applicable).

| Library         | Supported (tested) versions                                |
|-----------------|------------------------------------------------------------|
| W3EMC           | 2.9.1 and above                                            |

### Building the GSI Monitoring package

`CMake` employs an out-of-source build.  Create a directory for configuring the build and cd into it:

```bash
mkdir -p build && cd build
```

Set the compilers, if needed, to match those being used for compiling the TPL and NCEPLibs listed above: `FC` environment variable can be used to point to the desired Fortran compiler.

Execute `cmake` from inside your build directory.

```bash
cmake -DCMAKE_INSTALL_PREFIX=<install-prefix> <CMAKE_OPTIONS> /path/to/GSI-Monitor-source
```

If the dependencies are not located in a path recognized by `cmake` e.g. `/usr/local`, it may be necessary to provide the appropriate environment variables e.g. `<package_ROOT>` or `CMAKE_PREFIX_PATH` so that `cmake` is able to locate these dependencies.

The installation prefix for GSI-Monitor tools is provided by the `cmake` command-line argument `-DCMAKE_INSTALL_PREFIX=<install-prefix>`

To build and install:

```
make -j<x>
make install
```

### CMake Options

CMake allows for various options that can be specified on the command line via `-DCMAKE_OPTION=VALUE` or from within the ccmake gui. The list of options currently available is as follows:

| Option              | Description (Default)                                |
|---------------------|------------------------------------------------------|
| `BUILD_UTIL_ALLMON` | Build All Monitoring utilities (`OFF`)               |
| `BUILD_UTIL_MINMON` | Build Minimization Monitoring utilities (`OFF`)      |
| `BUILD_UTIL_CONMON` | Build Conventional Monitoring utilities (`OFF`)      |
| `BUILD_UTIL_OZNMON` | Build Ozone Monitoring utilities (`OFF`)             |
| `BUILD_UTIL_RADMON` | Build Radiance Monitoring utilities (`OFF`)          |


# Upset 3D
## 3D Code Suite for GameMaker

Upset 3D is a collection of classes, scripts, sprite, and objects that provide a clean starting point for anyone who wishes to make 3D games in the GameMaker engine. The system is designed to be modular, clean, and flexible to make customizing or expanding it as easy as possible for your project.

Upset 3D lays down the groundwork for small-cale 3D games while leaving the door open for easy expansion that may be necessary for your project. This suite provides a PBR rendering system with glTF model importing and skeletal animation as well as a basic 3D collision detection system with spatial partitioning.

GameMaker does not support user-defined threading, compute shaders, nor shader storage buffers at this time. As such, a number of important systems will be slow and limited; two of which being collision detection and skeletal animation. Some limitations are worked around through custom C++ libraries but note that these libraries are only supported and compiled for the explicitly supported platforms below. Should GameMaker start including some of these necessary features, the systems will be moved over to GameMaker-native calls.

## Requirements

* GameMaker 2024.1100 ~~(or later)~~

## Platform Support

* **Windows (U3D Full, MT, VM/YYC)**
* **Linux (U3D Full, MT, VM/YYC)**
* GX (U3D Compatability, VM)
* Android (U3D Compatability, VM / YYC)
* Switch (U3D Compatability, VM)
* *XBox (TBD)*
* *Playstation (Untested)*
* *IOS (Untested)*
* *Mac OS (Untested)*

Upset 3D only fully supports Windows and Linux platforms at this time and are the primary focus of this project.

| Flag | Description |
| --- | --- |
| U3D Full | Uses the full rendering pipeline with all available optimizations |
| U3D Compatability | Uses a limited rendering pipeline with much slower rendering performance |
| MT | Supports the external C++ libraries necessary to add multi-threading support |
| VM | Has been tested and works fully with GameMaker's VM target |
| YYC | Has been tested and works fully with GameMaker's YYC target |
| GMRT | Has been tested and works fully with GameMaker's new GMRT target |
| GMRT YYC | Has been tested and works fully with GameMaker's new GMRT YYC target |

Upset 3D's target platforms are Windows and Linux. These are the only two platforms, at the moment, that are guaranteed to work fully.

The system does have an experimental 'fall-back' rendering mode for platforms that require GLSL ES and this has been tested on GX (VM), Android (VM / YYC) and some consoles (VM) with success. Rendering features are not optimized in this case and  performance will be sub-par. I would like to improve this mode down the line but it is currently low-prio.

## Getting the Code

This repository contains a GameMaker project with the Upset3D native code, along with a code suite of tests to test various features of the system, and C++ scripts and headers for any external code. Both of these are located in the [source](https://github.com/Binsk/u3d-development/tree/master/source) folder.

### Pre-Built (recommended)

You can download a project template from the [releases](https://github.com/Binsk/u3d-development/releases) section which will include the Upset3D system along with compiled C++ libraries for any external systems.

### Manual Build

Clone the repository:
~~~
git clone https://github.com/Binsk/u3d-development.git
~~~

Launch GameMaker and load the project file located in `./u3d-development/source/gm-project/upset3d-engine.yyp`

The project should be runnable and will contain both Upset3D code and the code for a tech-demo, which is used to test various aspects of the system. At this point **no** C++ libraries will be available. This need to be built manually.

#### Linux Setup

Make sure you have gcc installed. 

Once gcc is installed, navigate into `./u3d-development/source/cpp` where you can then execute the following to build and install the C++ libraries into the local GameMaker project.

```
make build
```

This will compile the libraries and place them into `./u3d-development/source/cpp/bin`. Once built, you can optionally install the binaries into the local GameMaker project with:

```
make install
```

This will copy the compiled binaries into the relevant `./u3d-development/source/gm-project/extensions/*` folders.

#### Windows Setup

Make sure you have MinGW installed. The version used for my own personal testing is [WinLibs](https://winlibs.com/). Once installed make sure that the executable `mingw32-make` is accessible globaly in your terminal of choice.

Once MinGW is installed, navigate into `./u3d-development/source/cpp` where you can then execute the following to build and install the C++ libraries into the local GameMaker project.

```
mingw32-make build
```

This will compile the libraries and place them into `./u3d-development/source/cpp/bin`. Once built, you can optionally install the binaries into the local GameMaker project with:

```
mingw32-make install
```

This will copy the compiled binaries into the relevant `./u3d-development/source/gm-project/extensions/*` folders.

On Windows you will also require three MinGW DLLs to be packaged along with your game due to the use of pthreads for multi-threading support. You can find the following DLLs in your MinGW install directory and you should copy them into `./u3d-development/source/gm-project/datafiles`

* libgcc_s_seh-1.dll
* libstdc++-6.dll
* libwinpthread-1.dll

These DLLs are MIT licensed.

## Developer Support

Are you finding this project useful? Feel free to buy me a [coffee](https://ko-fi.com/binsk) if you are so inclined!

If that's not to your taste then I'd still be happy just to see what you've created with this project! Shoot me a link on the [GameMaker forums](https://forum.gamemaker.io/index.php?members/binsk.1097/)!

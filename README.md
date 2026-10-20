# Mac Game Installer

One `.pkg` that installs three community projects for playing Nintendo Switch games natively on Apple silicon Macs:

| Installs | Game | Upstream project | Needs |
| --- | --- | --- | --- |
| **Sky Recomp.app** | The Legend of Zelda: Skyward Sword HD | [Apolinario-coder/SkyRecomp](https://github.com/Apolinario-coder/SkyRecomp) | macOS 15+, your uncompressed v1.0.0 game files (`romfs` + `exefs`) |
| **Mush8.app** | Mario Kart 8 Deluxe | [c22dev/mush8](https://github.com/c22dev/mush8) | macOS 14+, a folder with `prod.keys`, base + update 4.0.1 `.nsp`, `Firmware` folder |
| **Build Tears of the Kingdom.app** | The Legend of Zelda: Tears of the Kingdom | [ly05010419/MacNativeGames](https://github.com/ly05010419/MacNativeGames) | macOS 26+, Homebrew, your 1.0.0 `.xci`/`.nsp` + `prod.keys`, 25 to 40 GB free |

Nothing here contains game data. Every app asks for your own dump, made from a Switch and a game you own.

Tears of the Kingdom is a helper rather than the game because MacNativeGames generates the `.app` from your game file: the finished app contains the game, so it can only be built on your Mac. The helper asks for your files with pickers, then runs the build in Terminal and places `Tears of the Kingdom.app` in Applications.

## Install

1. Download `Mac Game Installer-<version>.pkg` from [Releases](../../releases).
2. The package is not notarized, so macOS blocks a plain double-click. **Right-click the .pkg, choose Open, then Open again** (or allow it under System Settings > Privacy & Security).
3. Untick anything you do not want on the Installation Type step. Everything goes to `/Applications`.
4. Open each app and point it at your game files (details in the installer's Read Me page, or below).

If an installed app refuses to open, right-click it and choose Open once.

### Game files

- **Sky Recomp:** choose the folder with your extracted game files, click *Set up game files* (compiles the game code for your Mac, a few minutes), then *PLAY*. Esc opens settings. Data lives in `~/Library/Application Support/com.skyrecomp.app/`.
- **Mush8:** choose the folder holding `prod.keys`, the base and update `.nsp` files, the `Firmware` folder (and optionally the Booster Course Pass `.nsp`), click *Prepare* (extracts the game and compiles shaders, a few minutes), then play.
- **Build Tears of the Kingdom:** needs macOS 26, Homebrew, internet (for `opus`, `libvpx`, `python@3.14` and pinned sources) and about 25 GB free on the same APFS volume as the game file (40 GB with an update). Pick your `.xci`/`.nsp`, `prod.keys`, optionally an update `.nsp`/`.nsz`; for an `.nsp` base also your firmware dump folder. The build takes 10 to 30 minutes. Do not share the resulting app.

## Building the installer

The workflow `.github/workflows/build-installer.yml` (Actions tab, *Build installer*, *Run workflow*) builds Sky Recomp on a `macos-15` runner and Mush8 on `macos-26` (it needs Xcode 26), then packages them with the helper into the `.pkg`, test-installs it on the runner and attaches it to a release tagged `v<version>`. Inputs choose the upstream refs and the version. Roughly 30 to 60 minutes the first time; later runs reuse cached dependencies.

Locally, on an Apple silicon Mac with the two app bundles already built (see each project's docs):

```sh
mkdir apps && cp -R "/path/to/Sky Recomp.app" /path/to/Mush8.app apps/
tools/make-pkg.sh apps 0.1.0 out      # -> out/Mac Game Installer-0.1.0.pkg
```

`tools/make-pkg.sh` builds the helper app with `tools/build-totk-helper.sh` (an AppleScript app around `tools/build-totk.sh`), makes one component package per app with `pkgbuild`, and joins them with `productbuild` using `pkg/distribution.xml` and the pages in `pkg/resources/`.

## Layout

```
.github/workflows/build-installer.yml   builds the apps and the .pkg on GitHub's macOS runners
tools/make-pkg.sh                       apps dir + version -> the .pkg
tools/build-totk-helper.sh              builds "Build Tears of the Kingdom.app"
tools/build-totk.sh                     the script the helper runs: checks the Mac, installs tools, runs MacNativeGames
totk-helper/main.applescript            the helper's dialogs
pkg/distribution.xml, pkg/resources/    Installer window: choices, welcome, read me, conclusion
```

## Legal

Sky Recomp (MIT, based on LAS Recomp), Mush8 and MacNativeGames are independent projects by their authors; their licenses ship inside each app bundle. This repository holds only packaging scripts (MIT). Use the apps only with files dumped from your own console and your own copies of the games. Not affiliated with Nintendo.

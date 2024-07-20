# qemacs

## Introduction

Qemacs is an experiment in the building of standard kitchen sinks, also known as
[GNU Emacs] text editors so that developers can conveniently work with the latest
things.  As this is an experiment, there are many areas of improvement needed
and so it is highly encouraged to read the sources before using qemacs for
anything important.

The Quo-Emacs project consists of two repositories, this [qemacs] repository and
it's counterpart [.qemacs.d].

The [qemacs] project consists of a `Makefile` and some `BASH` shell scripts which
support the overall `Quo-Emacs` project. These shell scripts do not use the
standard `~/.emacs.d` path and instead initialize with `~/.qemacs.d` by default.

The [.qemacs.d] project consists of a starting point for `~/.qemacs.d`
customized configurations for use with [qemacs].

## Hardware and Operating System Requirements

- ARM64 or AMD64
- [Devuan], [Debian] or [Ubuntu]

Other linux distributions are encouraged but require the developer to figure out
what the distribution-specific dependencies are and how to install them. A good
starting point is the package names used to install the necessary debian
packages.

## Installation

Select a local path for qemacs to live, could be anywhere, `/usr/local/qemacs`,
`/opt/qemacs`, `~/src/qemacs` or wherever else makes sense for the developer
environment. For this example, let's use `/opt/qemacs`.

Run `git clone https://github.com/quo-emacs/qemacs.git .` to get a clone started,
or fork this repository and clone that instead.

Change into the qemacs clone directory and run: `make debian-deps` to install the
terminal user-interface dependencies, and then optionally run `make debian-deps-with-x`
to include the graphical user-interface dependencies.

Once the dependencies are installed: `make emacs` for the default which includes
support for graphical (x) environments, or run `make emacs-nox` for a build that
has no graphical supports included (terminal only).

Here's an example shell session performing these steps:

``` bash
#: create the directory first because /opt is typically owned by root
sudo mkdir -p /opt/qemacs

#: change the ownership to the current USER and GROUP
QEMACS_USER=$(id -u -n)
QEMACS_GROUP=$(id -g -n)
sudo chown ${QEMACS_USER}:${QEMACS_GROUP} /opt/qemacs

#: change the working directory
cd /opt/qemacs

#: checkout a fork of this repo, or use this repo directly
#: (the trailing dot in the git command is important)
git clone https://github.com/quo-emacs/qemacs.git .

#: install the dependencies, note that the standard tree-sitter library
#: is omitted because it is downloaded and built separately along with
#: GNU Emacs

#: use debian-deps for terminal user-interface support
make debian-deps

#: optional: install graphical user-interface dependencies
make debian-deps-with-x

#: if building with graphical support, run:
make emacs
#: or for terminal-only environments, run:
make emacs-nox

#: optional: create the terminal IDE wrapper script
make qide-sh

#: optional: create the graphical IDE wrapper script
make qxide-sh

#: install script symlinks to somewhere within the PATH environment
make INSTALL_BIN_PATH=/usr/local/bin install

#: there is also an uninstall target that will remove the files added to the
#: INSTALL_BIN_PATH.  To use that, call it the same as how the install target
#: was invoked, for example:
#:  make INSTALL_BIN_PATH=/usr/local/bin uninstall

#: with all of that completed, the last step is to setup the default
#: configuration.
#: Note: that it is highly encouraged to fork the starting point github repo:
#: https://github.com/quo-emacs/.qemacs.d
#: and clone the fork so that developers can backup and distribute their
#: configurations to as many environments as needed. The forks can be private
#: or even hosted on any other version controll platform such as GitLab and so
#: on.
git clone <forked-repository>/.qemacs.d.git ~/.qemacs.d
```

## Makefile

``` bash
$ make help
usage: make <help|clean|distclean|realclean>
       make <tree-sitter|emacs|emacs-nox>
       make <emacs-sh|xemacs-sh>
       make <qemacs-sh|qxemacs-sh>
       make <qide-sh|qxide-sh>
       make <scripts|scripts-nox|scripts-all>
       make <install|uninstall>
       make <purge-install|purge-sources|purge-archives>

TARGETS:

  help                   display this screen
  clean                  remove /quo/src/github.com/quo-emacs/qemacs/usr/{bin,include,lib,libexec,share}
  distclean              clean + remove /quo/src/github.com/quo-emacs/qemacs/src/{tree-sitter,emacs}
  realclean              distclean + remove /quo/src/github.com/quo-emacs/qemacs/src/{tree-sitter,emacs}*.tar.gz}
  tree-sitter            build tree-sitter library

  emacs                  build tree-sitter and emacs (with x)
  emacs-nox              build tree-sitter and emacs (without x)

  emacs-sh               create emacs shell script
  xemacs-sh              create xemacs shell script
  qemacs-sh              create qemacs shell script
  qxemacs-sh             create qxemacs shell script
  qide-sh                create qide shell script
  qxide-sh               create qxide shell script

  scripts-nox            make emacs-sh qemacs-sh
  scripts-nox-all        make scripts-nox qide-sh
  scripts                make scripts-nox xemacs-sh qxemacs-sh
  scripts-all            make scripts qide-sh qxide-sh

  install                make symlinks to /usr/local/bin
  uninstall              remove symlinks from /usr/local/bin

VARIABLES:

  EMACS_VERSION          version of emacs (29.4)
  TREE_SITTER_VERSION    version of tree-sitter (0.22.6)
  INSTALL_BIN_PATH       install bin path (/usr/local/bin)

INSTRUCTIONS:

The first thing to do is to "make emacs" or "make emacs-nox".
Both of these targets will download and build tree-sitter first.
Once a build has completed successfully, run "make install"
to have symlinks added to /usr/local/bin (sudo may be needed).
```

## Shell Scripting

All of the shell scripts have hard-coded absolute paths to the `qemacs` project
checkout. These scripts can be placed anywhere in the developer's `PATH`
environment.

### Profiles

The shell scripts support configurable "profiles", which really amount to
secondary clones of `~/.emacs.d` things. Whatever profile name is given, emacs
is invoked using `--init-directory=~/.<profile>.d`. This makes for the trivial
compartmentalization of work and personal project development environments.

There are a number of ways to specify the profile used:

* `--profile <name>` command line argument
* `QEMACS_PROFILE=<name>` environment variable

### Servers

There is also support for running emacs services. All of the shell scripts which
start with the letter "q" are servers as well as foreground instances. This way
developers can have one running instance and be able to easily open files from
other terminal sessions without having to copy/paste paths and finding the files
within emacs manually. These scripts accept an extra command line argument to
configure the name of the emacs server started. This allows for multiple `qemacs`
instances all running at the same time, using the same profile and yet disconnected
from each other.

Similar to the profiles concept, there are a number of ways to specify the server
name used:

* `--server <name>` command line argument
* `QEMACS_SERVER=<name>` environment variable

## Shell Scripts

### emacs

Start up a plain emacs instance providing only terminal user-interface support
(always uses the `-nw` option).

``` bash
$ emacs -h
usage: emacs [options]

options:

  -p | --profile=<name>      use ~/.<name>.d
  -d | --debug               debug-on-error t
  -D | --debug-init          debug-on-error t, with --debug-init
  -v | --verbose             display script settings

Arguments after a -- flag are passed unmodified to emacs.
```

### xemacs

The graphical `xemacs` is identical to the `emacs` script except that it does
not include the `-nw` flag when calling the qemacs built emacs binary.

``` bash
$ xemacs -h
usage: xemacs [options]

options:

  -p | --profile=<name>      use ~/.<name>.d
  -d | --debug               debug-on-error t
  -D | --debug-init          debug-on-error t, with --debug-init
  -v | --verbose             display script settings

Arguments after a -- flag are passed unmodified to emacs.
```

### qemacs

The `qemacs` script is the same as the `emacs` script except that the terminal
instance includes an emacs server. The first time `qemacs` is run, the instance
and server are started and calling `qemacs` from anywhere else will interact with
that instance (without opening any new instances).

While there is a command line argument to start an server already present within
the emacs binary, `qemacs` takes a different approach and simply sets two
environment variables: `QEMACS_SERVER=<name>` and
`QEMACS_SERVER_START=true`. The latter instructs the [.qemacs.d] configuration
to startup a server and the former specifies the name of the server to use when
doing so. The reasoning behind this is to allow developers the opportunity to
customize the emacs environment before starting the service.

``` bash
$ qemacs -h
usage: qemacs [options]

options:

  -p | --profile=<name>      use ~/.<name>.d
  -s | --server=<name>       specify server <name>
  -d | --debug               debug-on-error t
  -D | --debug-init          debug-on-error t, with --debug-init
  -v | --verbose             display script settings

Arguments after a -- flag are passed unmodified to emacs.
```

### qxemacs

The `qxemacs` script is the same as the `xemacs` script except that the terminal
instance includes an emacs server. The first time `qxemacs` is run, the instance
and server are started and calling `qxemacs` from anywhere else will interact with
that graphical instance (without opening any new instances).

``` bash
$ qxemacs -h
usage: qxemacs [options]

options:

  -p | --profile=<name>      use ~/.<name>.d
  -s | --server=<name>       specify server <name>
  -d | --debug               debug-on-error t
  -D | --debug-init          debug-on-error t, with --debug-init
  -v | --verbose             display script settings

Arguments after a -- flag are passed unmodified to emacs.
```

### qide

The `qide` script is where the generic applicability of the qemacs project starts
to diverge with the other scripts outlined previously.

The `qide` script is like the `qemacs` script with the exception that it sets a
`QEMACS_IDE=true` environment variable which is intended to be used by the `~/.qemacs.d`
configuration to provide a formal integrated development environment as opposed to
a standard text editor that does syntax highlighting and so on.

The [.qemacs.d] project handles the `QEMACS_IDE` variable by configuring emacs
for [lsp-mode] and [dape] features as well as using [treemacs] instead of
[neotree]. There are more differences of course and it is encouraged that
developers using [qemacs] and [.qemacs.d] read the source code to understand
what's happening and tailor their integrated development environment to their
specific needs.

The reasoning for this feature is to allow developers to have an excellent command
line text editor with lots of fancy things that just happens to be the same editor
used for formal integrated development environments with all the additional features
needed in those cases. All of the previously described shell scripts use [neotree]
and have no formal language or debugging development supports. This means if one
needs to simply edit some config file, use the `*emacs` ones and for dedicated
development sessions where one is working on multiple projects and need to be able
to debug running processes, use the `*ide` scripts instead.

``` bash
$ qide -h
usage: qide [options]

options:

  -p | --profile=<name>      use ~/.<name>.d
  -s | --server=<name>       specify server <name>
  -d | --debug               debug-on-error t
  -D | --debug-init          debug-on-error t, with --debug-init
  -v | --verbose             display script settings

Arguments after a -- flag are passed unmodified to emacs.
```

### qxide

The `qxide` is essentially a combination of `qxemacs` and `qide`.

``` bash
$ qxide -h
usage: qxide [options]

options:

  -p | --profile=<name>      use ~/.<name>.d
  -s | --server=<name>       specify server <name>
  -d | --debug               debug-on-error t
  -D | --debug-init          debug-on-error t, with --debug-init
  -v | --verbose             display script settings

Arguments after a -- flag are passed unmodified to emacs.
```

## License

The [qemacs] project is licensed under the terms and conditions of the GNU GPL
version 2.0 only (see: [gpl-2.0-only]).

The LICENSE this project applies to the contents of this git repository and does
not apply in any way, shape, or form, to the tree-sitter or [GNU Emacs]
projects, nor does this project distribute tree-sitter or [GNU Emacs] source
code.

There are no source changes to tree-sitter or [GNU Emacs]. This is as vanilla as
it gets with respect to the usage of tree-sitter and [GNU Emacs] codebases.

[qemacs]: https://github.com/quo-emacs/qemacs
[.qemacs.d]: https://github.com/quo-emacs/.qemacs.d
[Devuan]: https://devuan.org
[Debian]: https://debian.org
[Ubuntu]: https://ubuntu.com
[GNU Emacs]: https://www.gnu.org/software/emacs
[treemacs]: https://github.com/Alexander-Miller/treemacs
[neotree]: https://github.com/jaypei/emacs-neotree
[lsp-mode]: https://emacs-lsp.github.io/lsp-mode
[dape]: https://github.com/svaante/dape
[gpl-2.0-only]: https://spdx.org/licenses/GPL-2.0-only.html

#!/usr/bin/env make -f

# Copyright (C) 2024 The Quo-Emacs Authors
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation; version 2.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
# PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, write to the Free Software Foundation, Inc., 51 Franklin
# Street, Fifth Floor, Boston, MA 02110-1301, USA.

SHELL := /bin/bash

DEB_VER ?= $(shell \
	if [ -f /etc/debian_version ]; then \
		cat /etc/debian_version \
			| perl -pe 's!^\s*(\d+)(?:\.\d+)??\s*$$!$$1!'; \
	fi)

#
#: Site Variables
#

# current working directory
CWD := $(shell pwd)
# shell script templates
TMPL_PATH := ${CWD}/_templates
# internal installation path
USR_PATH := ${CWD}/usr
# internal source build path
SRC_PATH := ${CWD}/src

#
#: GCC
#

GCC_VER ?= $(shell \
	if [ -n "${DEB_VER}" ]; then \
		if   [ "${DEB_VER}" == "11" ]; then echo "10"; \
		elif [ "${DEB_VER}" == "12" ]; then echo "11"; \
		elif [ "${DEB_VER}" == "13" ]; then echo "12"; \
		fi; \
	fi)

#
#: Emacs
#

GNU_BASEURL   ?= https://ftp.gnu.org/gnu
EMACS_VERSION ?= 29.4

EMACS_CFLAGS := -O3 \
    -fno-math-errno -funsafe-math-optimizations -fno-finite-math-only -fno-trapping-math \
    -freciprocal-math -fno-rounding-math -fno-signaling-nans \
    -fassociative-math -fno-signed-zeros -frename-registers -funroll-loops \
    -mtune=native -march=native -fomit-frame-pointer

EMACS_BIN       := ${USR_PATH}/bin/emacs-${EMACS_VERSION}
EMACSCLIENT_BIN := ${USR_PATH}/bin/emacsclient

INSTALL_BIN_PATH ?= /usr/local/bin
ALL_BIN_FILES    += ctags etags ebrowse
ALL_BIN_FILES    += emacs-${EMACS_VERSION} emacsclient
ALL_BIN_FILES    += emacs xemacs qemacs qxemacs qide qxide

#
#: tree sitter
#

TREE_SITTER_GITHUB ?= https://github.com/tree-sitter
TREE_SITTER_VERSION ?= 0.22.6
TREE_SITTER_BASEURL ?= ${TREE_SITTER_GITHUB}/tree-sitter/archive/refs/tags

#
#: PHP Support
#

PHPACTOR_PHAR_URL ?= https://github.com/phpactor/phpactor/releases/latest/download/phpactor.phar
ALL_BIN_FILES     += phpactor

PHPUNIT_PHAR_URL  ?= https://phar.phpunit.de/phpunit-11.phar
ALL_BIN_FILES     += phpunit

COMPOSER_PHAR_URL ?= https://getcomposer.org/download/latest-stable/composer.phar
ALL_BIN_FILES     += composer

#
#: Internal Helpers
#

#: 0=extracted 1=remote-url 2=remote-file 3=local-file
define _download_extract
	if [ ! -f "$(3)" ]; then \
		if [ ! -f "$(2)" ]; then \
			wget -c "$(1)"; \
		fi; \
		if [ "$(2)" != "$(3)" ]; then \
			mv -v "$(2)" "$(3)"; \
		fi; \
	fi; \
	if [ ! -d "$(0)" ]; then \
		tar xf "$(3)"; \
	fi
endef

#: 1=common 2=script 3=destination
define _make_template
	if [ -f "${TMPL_PATH}/$(2).bash" ]; then \
		cp  "${TMPL_PATH}/$(1).bash"                                  "$(3)"; \
		cat "${TMPL_PATH}/$(2).bash"                               >> "$(3)"; \
		perl -pi -e 's!\Q{{USR_PATH}}\E!${USR_PATH}!g;'               "$(3)"; \
		perl -pi -e 's!\Q{{EMACS_BIN}}\E!${EMACS_BIN}!g;'             "$(3)"; \
		perl -pi -e 's!\Q{{EMACSCLIENT_BIN}}\E!${EMACSCLIENT_BIN}!g;' "$(3)"; \
	fi
endef

#
#: Make Targets
#

.PHONY: help clean distclean realclean
.PHONY: tree-sitter emacs emacs-only emacs-nox emacs-nox-only
.PHONY: emacs-sh xemacs-sh qemacs-sh qxemacs-sh qide-sh qxide-sh
.PHONY: scripts scripts-all scripts-nox scripts-nox-all
.PHONY: install install-nox uninstall
.PHONY: composer phpactor phpunit

help:
	@echo "usage: make <help|clean|distclean|realclean>"
	@echo "       make <tree-sitter|emacs|emacs-nox>"
	@echo "       make <emacs-sh|xemacs-sh>"
	@echo "       make <qemacs-sh|qxemacs-sh>"
	@echo "       make <qide-sh|qxide-sh>"
	@echo "       make <scripts|scripts-nox|scripts-all>"
	@echo "       make <install|uninstall>"
	@echo "       make <purge-install|purge-sources|purge-archives>"
	@echo
	@echo "TARGETS:"
	@echo
	@echo "  help                   display this screen"
	@echo "  clean                  remove ${USR_PATH}/{bin,include,lib,libexec,share}"
	@echo "  distclean              clean + remove ${SRC_PATH}/{tree-sitter,emacs}"
	@echo "  realclean              distclean + remove ${SRC_PATH}/{tree-sitter,emacs}*.tar.gz}"
	@echo "  tree-sitter            build tree-sitter library"
	@echo
	@echo "  emacs                  build tree-sitter and emacs (with x)"
	@echo "  emacs-nox              build tree-sitter and emacs (without x)"
	@echo
	@echo "  emacs-sh               create emacs shell script"
	@echo "  xemacs-sh              create xemacs shell script"
	@echo "  qemacs-sh              create qemacs shell script"
	@echo "  qxemacs-sh             create qxemacs shell script"
	@echo "  qide-sh                create qide shell script"
	@echo "  qxide-sh               create qxide shell script"
	@echo
	@echo "  scripts-nox            make emacs-sh qemacs-sh"
	@echo "  scripts-nox-all        make scripts-nox qide-sh"
	@echo "  scripts                make scripts-nox xemacs-sh qxemacs-sh"
	@echo "  scripts-all            make scripts qide-sh qxide-sh"
	@echo
	@echo "  install                make symlinks to ${INSTALL_BIN_PATH}"
	@echo "  uninstall              remove symlinks from ${INSTALL_BIN_PATH}"
	@echo
	@echo "VARIABLES:"
	@echo
	@echo "  EMACS_VERSION          version of emacs (${EMACS_VERSION})"
	@echo "  TREE_SITTER_VERSION    version of tree-sitter (${TREE_SITTER_VERSION})"
	@echo "  INSTALL_BIN_PATH       install bin path (${INSTALL_BIN_PATH})"
	@echo
	@echo "INSTRUCTIONS:"
	@echo
	@echo "The first thing to do is to \"make emacs\" or \"make emacs-nox\"."
	@echo "Both of these targets will download and build tree-sitter first."
	@echo "Once a build has completed successfully, run \"make install\""
	@echo "to have symlinks added to ${INSTALL_BIN_PATH} (sudo may be needed)."

clean:
	@echo "# removing ./usr"
	@rm -rfv ${USR_PATH} || true

distclean: clean
	@echo "# removing ./src (directories only)"
	@for dir in $(shell ls -d "${SRC_PATH}"/* | grep -v '\.tar\.gz'); do \
		rm -rfv "$${dir}"; \
	done

realclean: distclean
	@echo "# removing ./src (everything else)"
	@rm -rfv "${SRC_PATH}"

_init:
	@mkdir -vp \
		"${SRC_PATH}" \
		"${USR_PATH}"/{bin,include,lib,libexec,share}

#
#: Dependency Targets
#

ifneq (${DEB_VER},)

DEB_DEPS += aspell
DEB_DEPS += build-essential
DEB_DEPS += libgnutls28-dev
DEB_DEPS += zlib1g-dev
DEB_DEPS += libncurses5-dev
DEB_DEPS += texinfo
DEB_DEPS += libjansson4
DEB_DEPS += libjansson-dev
DEB_DEPS += libgccjit0
DEB_DEPS += libgccjit-${GCC_VER}-dev
DEB_DEPS += gcc-${GCC_VER}
DEB_DEPS += g++-${GCC_VER}
DEB_DEPS += autoconf
DEB_DEPS += automake
DEB_DEPS += pkg-config
DEB_DEPS += shared-mime-info
DEB_DEPS += sharutils
DEB_DEPS += uuid-dev
DEB_DEPS += libtool
DEB_DEPS += libpcre2-dev
DEB_DEPS += libpcre2-posix3
DEB_DEPS += liblzma-dev
DEB_DEPS += liblzo2-2
DEB_DEPS += liblockfile-dev
DEB_DEPS += libgpm-dev
DEB_DEPS += libdeflate-dev
DEB_DEPS += intltool-debian
DEB_DEPS += autopoint
DEB_DEPS += libasprintf-dev
DEB_DEPS += libgettextpo-dev
DEB_DEPS += cargo

debian-deps:
	@echo "# run the following apt install command?"
	@echo "sudo apt install ${DEB_DEPS}"
	@echo
	@read -r -n 1 -p "# <ctrl+c> to interrupt, <enter> to continue... " \
		&& sudo apt install ${DEB_DEPS}

DEB_DEPS_X += libgtk-3-dev
DEB_DEPS_X += libtiff5-dev
DEB_DEPS_X += libgif-dev
DEB_DEPS_X += libjpeg-dev
DEB_DEPS_X += libpng-dev
DEB_DEPS_X += libxpm-dev
DEB_DEPS_X += libx11-dev
DEB_DEPS_X += libmagickcore-dev
DEB_DEPS_X += libmagick++-dev
DEB_DEPS_X += libgtk-3-dev
DEB_DEPS_X += libwebkit2gtk-4.0-dev

debian-deps-with-x:
	@echo "# run the following apt install command?"
	@echo "sudo apt install ${DEB_DEPS_X}"
	@echo
	@read -r -n 1 -p "# <ctrl+c> to interrupt, <enter> to continue... " \
		&& sudo apt install ${DEB_DEPS_X}

endif

#
#: General Programming Utilities
#

composer: _init
	@if [ -f "${USR_PATH}/bin/composer" ]; then \
		echo "# found existing composer"; \
	else  \
		echo "# installing latest composer release"; \
		pushd "${SRC_PATH}" > /dev/null; \
			wget --show-progress -c ${COMPOSER_PHAR_URL}; \
			mv -v composer.phar "${USR_PATH}/bin/composer"; \
		popd > /dev/null; \
	fi
	@chmod -v +x "${USR_PATH}/bin/composer"

phpactor: _init
	@echo "# installing latest phpactor release"
	@pushd "${SRC_PATH}" > /dev/null; \
		wget --show-progress --no-verbose -c ${PHPACTOR_PHAR_URL}; \
		mv -v phpactor.phar "${USR_PATH}/bin/phpactor"; \
	popd > /dev/null
	@chmod -v +x "${USR_PATH}/bin/phpactor"

phpunit: _init
	@echo "# installing phpunit-11"
	@pushd "${SRC_PATH}" > /dev/null; \
		wget --show-progress --no-verbose -c ${PHPUNIT_PHAR_URL}; \
		mv -v phpunit-11.phar "${USR_PATH}/bin/phpunit"; \
	popd > /dev/null
	@chmod -v +x "${USR_PATH}/bin/phpunit"

#
#: Emacs Build Dependencies
#

tree-sitter: export PREFIX=${USR_PATH}
tree-sitter: export prefix=${USR_PATH}
tree-sitter: TAR_NAME=tree-sitter-${TREE_SITTER_VERSION}
tree-sitter: TAR_FILE_REMOTE=v${TREE_SITTER_VERSION}.tar.gz
tree-sitter: TAR_FILE_LOCAL=tree-sitter-${TREE_SITTER_VERSION}.tar.gz
tree-sitter: TAR_URL=${TREE_SITTER_BASEURL}/${TAR_FILE_REMOTE}
tree-sitter: _init
	@mkdir -vp ${SRC_PATH}/${TAR_NAME}
	@pushd ${SRC_PATH} > /dev/null; \
		$(call _download_extract ${TAR_NAME},${TAR_URL},${TAR_FILE_REMOTE},${TAR_FILE_LOCAL}); \
		pushd "${TAR_NAME}" > /dev/null; \
			make prefix="${USR_PATH}" -j$(shell nproc) clean all install; \
		popd > /dev/null; \
	popd > /dev/null

#
#: Emacs Build
#

emacs: tree-sitter emacs-only

emacs-only: TAR_NAME=emacs-${EMACS_VERSION}
emacs-only: TAR_FILE=${TAR_NAME}.tar.gz
emacs-only: TAR_URL=${GNU_BASEURL}/emacs/${TAR_FILE}
emacs-only:
	@mkdir -vp ${SRC_PATH}/${TAR_NAME}
	@pushd ${SRC_PATH} > /dev/null; \
		$(call _download_extract ${TAR_NAME},${TAR_URL},${TAR_FILE},${TAR_FILE}); \
		pushd "${TAR_NAME}" > /dev/null; \
			export PREFIX="${USR_PATH}"; \
			export CFLAGS="${CFLAGS} ${EMACS_CFLAGS} -I${USR_PATH}/include"; \
			export LDFLAGS="${LDFLAGS} -L${USR_PATH}/lib"; \
			export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${USR_PATH}/lib"; \
			export PKG_CONFIG_PATH="${PKG_CONFIG_PATH}:${USR_PATH}/lib/pkgconfig"; \
			make distclean; \
			./autogen.sh; \
			./configure \
					--prefix=${USR_PATH} \
					--with-all \
					--with-json \
					--with-imagemagick \
					--with-tree-sitter \
					--with-included-regex \
					--with-cairo \
					--with-xwidgets \
					--with-x-toolkit=gtk3 \
					--disable-build-details; \
			make -j$(shell nproc); \
			make prefix="${USR_PATH}" install-strip; \
		popd; \
	popd
	@$(MAKE) scripts

emacs-nox: tree-sitter emacs-nox-only

emacs-nox-only: TAR_NAME=emacs-${EMACS_VERSION}
emacs-nox-only: TAR_FILE=${TAR_NAME}.tar.gz
emacs-nox-only: TAR_URL=${GNU_BASEURL}/emacs/${TAR_FILE}
emacs-nox-only:
	@mkdir -vp ${SRC_PATH}/${TAR_NAME}
	@pushd ${SRC_PATH} > /dev/null; \
		$(call _download_extract ${TAR_NAME},${TAR_URL},${TAR_FILE},${TAR_FILE}); \
		pushd "${TAR_NAME}" > /dev/null; \
			export PREFIX="${USR_PATH}"; \
			export CFLAGS="${CFLAGS} ${EMACS_CFLAGS} -I${USR_PATH}/include"; \
			export LDFLAGS="${LDFLAGS} -L${USR_PATH}/lib"; \
			export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${USR_PATH}/lib"; \
			export PKG_CONFIG_PATH="${PKG_CONFIG_PATH}:${USR_PATH}/lib/pkgconfig"; \
			make distclean; \
			./autogen.sh; \
			./configure \
					--prefix=${USR_PATH} \
					--with-x-toolkit=no \
					--with-json \
					--with-tree-sitter \
					--with-included-regex \
					--without-x; \
			make -j$(shell nproc); \
			make prefix="${USR_PATH}" install-strip; \
		popd; \
	popd
	@$(MAKE) scripts-nox

#
#: Emacs Wrapper Scripts
#

emacs-sh: DST=${USR_PATH}/bin/emacs
emacs-sh: _init
	@if [ -L ${USR_PATH}/bin/emacs ]; then \
			echo "# removing emacs-${EMACS_VERSION} symlink"; \
			rm -vf ${USR_PATH}/bin/emacs; \
	fi
	@echo "# creating: ${DST}"
	@$(call _make_template,_common,emacs,${DST})
	@chmod +x ${DST}

xemacs-sh: DST=${USR_PATH}/bin/xemacs
xemacs-sh: _init
	@echo "# creating: ${DST}"
	@$(call _make_template,_common,xemacs,${DST})
	@chmod +x ${DST}

qemacs-sh: DST=${USR_PATH}/bin/qemacs
qemacs-sh: _init
	@echo "# creating: ${DST}"
	@$(call _make_template,_common_q,qemacs,${DST})
	@chmod +x ${DST}

qxemacs-sh: DST=${USR_PATH}/bin/qxemacs
qxemacs-sh: _init
	@echo "# creating: ${DST}"
	@$(call _make_template,_common_q,qxemacs,${DST})
	@chmod +x ${DST}

qide-sh: DST=${USR_PATH}/bin/qide
qide-sh: _init
	@echo "# creating: ${DST}"
	@$(call _make_template,_common_ide,qide,${DST})
	@chmod +x ${DST}

qxide-sh: DST=${USR_PATH}/bin/qxide
qxide-sh: _init
	@echo "# creating: ${DST}"
	@$(call _make_template,_common_ide,qxide,${DST})
	@chmod +x ${DST}

scripts: emacs-sh xemacs-sh qemacs-sh qxemacs-sh

scripts-all: scripts qide-sh qxide-sh

scripts-nox: emacs-sh qemacs-sh

scripts-nox-all: scripts-nox qide-sh

#
#: External Bin Path Installation
#

install:
	@echo "# installing emacs scripting to ${INSTALL_BIN_PATH}"
	@for FILE in ${ALL_BIN_FILES}; do \
			if [ -e "${USR_PATH}/bin/$${FILE}" ]; then \
				if [ -e "${INSTALL_BIN_PATH}/$${FILE}" ]; then \
					echo "# replacing: ${INSTALL_BIN_PATH}/$${FILE}"; \
					rm -fv "${INSTALL_BIN_PATH}/$${FILE}"; \
				else \
					echo "# symlinking: ${INSTALL_BIN_PATH}/$${FILE}"; \
				fi; \
				ln -sv "${USR_PATH}/bin/$${FILE}" "${INSTALL_BIN_PATH}/"; \
			fi; \
		done; \

uninstall:
	@echo "# removing files from ${INSTALL_BIN_PATH}"
	@for FILE in ${ALL_BIN_FILES}; do \
		if [ -e "${INSTALL_BIN_PATH}/$${FILE}" ]; then \
			rm -fv "${INSTALL_BIN_PATH}/$${FILE}"; \
		fi; \
	done

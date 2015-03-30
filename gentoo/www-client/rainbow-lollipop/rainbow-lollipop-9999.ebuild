# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

# Created by Peter Huewe

EAPI=5
inherit eutils
inherit git-r3
inherit cmake-utils
DESCRIPTION="the visual history browser"
HOMEPAGE="http://rainbow-lollipop.de/"
CMAKE_IN_SOURCE_BUILD="1"
EGIT_REPO_URI="https://github.com/grindhold/rainbow-lollipop.git"
KEYWORDS=""
LICENSE="GPL-3"
SLOT="0"

KEYWORDS="~x86 ~amd64"
DEPEND="
	>=dev-lang/vala-0.26
	<net-libs/zeromq-3
	net-libs/webkit-gtk:4
	dev-libs/libgee:0.8
	dev-util/pkgconfig
	>=dev-util/cmake-2.6
	dev-libs/glib
	x11-libs/gtk+:3
	media-libs/clutter:1.0
	media-libs/clutter-gtk:1.0
	dev-db/sqlite
	"

RDEPEND="${DEPEND}"

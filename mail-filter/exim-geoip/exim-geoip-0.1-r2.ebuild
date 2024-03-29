# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit autotools flag-o-matic git-r3

DESCRIPTION="MaxMind GeoIP2 dlfunc for Exim"
HOMEPAGE="https://dist.epipe.com/exim/
	https://github.com/andrewnimmo/exim-geoipv6-dlfunc"
EGIT_REPO_URI="https://github.com/andrewnimmo/exim-geoipv6-dlfunc"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="~amd64 ~x86"

DEPEND="dev-libs/libmaxminddb:=
	mail-mta/exim[dlfunc]"
RDEPEND="${DEPEND}"

#S="${WORKDIR}/exim-geoipv6-dlfunc-${PV}"

src_prepare() {
	default
	eautoreconf
}

src_configure() {
	append-cppflags "-I/usr/include/exim -DDLFUNC_IMPL"
	econf
}

src_install() {
	default
	find "${D}" -name '*.la' -delete || die "Failed to prune libtool files"
}

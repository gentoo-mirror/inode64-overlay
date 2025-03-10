# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Gentoo Linux update system"
HOMEPAGE="https://github.com/inode64/glus"

if [[ "${PV}" == *9999 ]] ; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/inode64/glus.git"
else
	KEYWORDS="~amd64 ~x86"
	SRC_URI="https://github.com/inode64/glus/archive/${PV}.tar.gz -> ${P}.tar.gz"
fi

LICENSE="MIT"
SLOT="0"

RDEPEND="${DEPEND}
	app-admin/perl-cleaner
	app-portage/gentoolkit
	virtual/mta
"

src_compile() {
	:
}

# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{10..13} )
inherit distutils-r1 pypi

DESCRIPTION="Cron expression parser and evaluator"
HOMEPAGE="https://github.com/cuu508/cronsim"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64"

distutils_enable_tests pytest

# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

MY_PN="KeyDB"

# N.B.: It is no clue in porting to Lua eclasses, as upstream have deviated
# too far from vanilla Lua, adding their own APIs like lua_enablereadonlytable

inherit edo multiprocessing systemd tmpfiles toolchain-funcs

DESCRIPTION="KeyDB is a high performance fork of Redis with a focus on multithreading"
HOMEPAGE="https://docs.keydb.dev/"
SRC_URI="https://github.com/Snapchat/${MY_PN}/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="curl flash +jemalloc ssl systemd tcmalloc test"
RESTRICT="!test? ( test )"

COMMON_DEPEND="
	app-arch/lz4
	app-arch/snappy
	app-arch/zstd
	curl? ( net-misc/curl )
	jemalloc? ( >=dev-libs/jemalloc-5.1:= )
	ssl? ( dev-libs/openssl:0= )
	systemd? ( sys-apps/systemd:= )
	tcmalloc? ( dev-util/google-perftools )
"

RDEPEND="
	${COMMON_DEPEND}
	acct-group/keydb
	acct-user/keydb
"

BDEPEND="
	${COMMON_DEPEND}
	virtual/pkgconfig
"

# Tcl is only needed in the CHOST test env
DEPEND="
	${COMMON_DEPEND}
	test? (
		dev-lang/tcl:0=
		ssl? ( dev-tcltk/tls )
	)"

REQUIRED_USE="?? ( jemalloc tcmalloc )"

PATCHES=(
	"${FILESDIR}/${PN}-6.3.2-config.patch"
	"${FILESDIR}/${PN}-sentinel-6.3.2-config.patch"
	"${FILESDIR}/${PN}-5.0-use-system-jemalloc.patch"
)

S="${WORKDIR}/${MY_PN}-${PV}"

src_compile() {
	local myconf=""

	if use jemalloc; then
		myconf+="MALLOC=jemalloc"
	elif use tcmalloc; then
		myconf+="MALLOC=tcmalloc"
	else
		myconf+="MALLOC=libc"
	fi
	if use ssl; then
		myconf+=" BUILD_TLS=yes"
	fi
	if use flash; then
		myconf+=" ENABLE_FASH=yes"
	fi
	if ! use curl; then
		myconf+=" NO_MOTD=yes"
	fi

	export USE_SYSTEMD=$(usex systemd)

	tc-export AR CC RANLIB
	emake V=1 ${myconf} AR="${AR}" CC="${CC}" RANLIB="${RANLIB}"
}

src_test() {
    # TODO: At the moment the test freezes and I have not found a solution
	local runtestargs=(
		--clients "$(makeopts_jobs)" # see bug #649868
		--skiptest "Active defrag eval scripts" # see bug #851654
		--verbose
	)

	if has usersandbox "${FEATURES}" || ! has userpriv "${FEATURES}"; then
		ewarn "oom-score-adj related tests will be skipped." \
			"They are known to fail with FEATURES usersandbox or -userpriv. See bug #756382."

		runtestargs+=(
			# unit/oom-score-adj was introduced in version 6.2.0
			--skipunit unit/oom-score-adj # see bug #756382

			# Following test was added in version 7.0.0 to unit/introspection.
			# It also tries to adjust OOM score.
			--skiptest "CONFIG SET rollback on apply error"
		)
	fi

	if use ssl; then
		edo ./utils/gen-test-certs.sh
		runtestargs+=( --tls )
	fi

	edo ./runtest "${runtestargs[@]}"
}

src_install() {
	insinto /etc/keydb
	doins keydb.conf sentinel.conf
	use prefix || fowners -R keydb:keydb /etc/keydb /etc/keydb/{keydb,sentinel}.conf
	fperms 0750 /etc/keydb
	fperms 0644 /etc/keydb/{keydb,sentinel}.conf

	newconfd "${FILESDIR}/keydb.confd-r2" keydb
	newinitd "${FILESDIR}/keydb.initd-6" keydb

	systemd_newunit "${FILESDIR}/keydb.service-4" keydb.service
	newtmpfiles "${FILESDIR}/keydb.tmpfiles-2" keydb.conf

	newconfd "${FILESDIR}/keydb-sentinel.confd-r1" keydb-sentinel
	newinitd "${FILESDIR}/keydb-sentinel.initd-r1" keydb-sentinel

	insinto /etc/logrotate.d/
	newins "${FILESDIR}/${PN}.logrotate" "${PN}"

	dodoc 00-RELEASENOTES README.md

	if use ssl; then
	    dodoc TLS.md
	fi

	dobin src/keydb-cli
	dosbin src/keydb-benchmark src/keydb-server src/keydb-check-aof src/keydb-check-rdb src/keydb-diagnostic-tool
	fperms 0750 /usr/sbin/keydb-benchmark
	dosym keydb-server /usr/sbin/keydb-sentinel

	if use prefix; then
		diropts -m0750
	else
		diropts -m0750 -o keydb -g keydb
	fi
	keepdir /var/{log,lib}/keydb
}

pkg_postinst() {
	tmpfiles_process keydb.conf

	ewarn "The default keydb configuration file location changed to:"
	ewarn "  /etc/keydb/{keydb,sentinel}.conf"
	ewarn "Please apply your changes to the new configuration files."
}

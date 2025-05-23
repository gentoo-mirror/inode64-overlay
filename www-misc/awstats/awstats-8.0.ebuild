# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

MY_P=${PN}-${PV%_p*}

DESCRIPTION="AWStats is short for Advanced Web Statistics"
HOMEPAGE="https://www.awstats.org/"
SRC_URI="https://www.awstats.org/files/${P}.tar.gz"

S=${WORKDIR}/${MY_P}
LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64 ~riscv ~x86"
IUSE="geoip2 ipv6"

RDEPEND="
	>=dev-lang/perl-5.6.1
	dev-perl/URI
	virtual/perl-Time-Local
	geoip2? (
		dev-perl/GeoIP2
	)
	ipv6? (
		dev-perl/Net-DNS
		dev-perl/Net-IP
	)
"
HTML_DOCS="docs/"
DOCS="README.md"

src_prepare() {
	default

	# change default installation directory
	find . -type f -exec sed \
		-e "s#/usr/local/awstats/wwwroot#/usr/share/awstats/wwwroot#g" \
		-e '/PossibleLibDir/s:(.*):("/usr/share/awstats/wwwroot/cgi-bin/lib"):' \
		-i {} + || die "find/sed failed"

	# set default values for directories; use apache log as an example
	sed \
		-e "s|^\(LogFile=\).*$|\1\"/var/log/apache2/access_log\"|" \
		-e "s|^\(SiteDomain=\).*$|\1\"localhost\"|" \
		-e "s|^\(DirIcons=\).*$|\1\"/awstats/icon\"|" \
		-i "${S}"/wwwroot/cgi-bin/awstats.model.conf || die "sed failed"

	# enable plugins

	if use ipv6; then
		sed -e "s|^#\(LoadPlugin=\"ipv6\"\)$|\1|" \
			-i "${S}"/wwwroot/cgi-bin/awstats.model.conf || die "sed failed"
	fi

	if use geoip2; then
		sed -e '/LoadPlugin="geoip2_country /aLoadPlugin="geoip2_country /usr/share/GeoIP/GeoLite2-Country.mmdb"' \
			-i "${S}"/wwwroot/cgi-bin/awstats.model.conf || die "sed failed"
		sed -e '/LoadPlugin="geoip2_city /aLoadPlugin="geoip2_city /usr/share/GeoIP/GeoLite2-City.mmdb"' \
			-i "${S}"/wwwroot/cgi-bin/awstats.model.conf || die "sed failed"
	fi

	find "${S}" '(' -type f -not -name '*.pl' ')' -exec chmod -x {} + || die

	eapply_user
}

src_install() {
	einstalldocs

	newdoc wwwroot/cgi-bin/plugins/example/example.pm example_plugin.pm
	dodoc -r tools/xslt

	keepdir /var/lib/awstats

	insinto /etc/awstats
	doins "${S}"/wwwroot/cgi-bin/awstats.model.conf

	# remove extra content that we don't want to install
	rm -r "${S}"/wwwroot/cgi-bin/awstats.model.conf \
		"${S}"/wwwroot/classes/src || die

	insinto /usr/share/awstats
	doins -r wwwroot
	chmod +x "${D}"/usr/share/awstats/wwwroot/cgi-bin/*.pl

	cd "${S}"/tools
	dobin awstats_buildstaticpages.pl awstats_exportlib.pl \
		awstats_updateall.pl
	newbin logresolvemerge.pl awstats_logresolvemerge.pl
	newbin maillogconvert.pl awstats_maillogconvert.pl
	newbin urlaliasbuilder.pl awstats_urlaliasbuilder.pl

	dosym ../share/awstats/wwwroot/cgi-bin/awstats.pl /usr/bin/awstats.pl
}

pkg_postinst() {
	elog "The AWStats-Manual is available either inside"
	elog "the /usr/share/doc/${PF} - folder, or at"
	elog "https://awstats.sourceforge.net/docs/index.html ."
	elog
	elog "Copy the /etc/awstats/awstats.model.conf to"
	elog "/etc/awstats/awstats.<yourdomain>.conf and edit it."
	elog ""
	ewarn "This ebuild does no longer use webapp-config to install"
	ewarn "instead you should point your configuration to the stable"
	ewarn "directory tree in the following path:"
	ewarn "	   /usr/share/awstats"
}

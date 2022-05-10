geoip2-database-deb :: OSSO build of MaxMind.com geoip2-database-*
==================================================================

Usage::

    MAXMIND_LICENSE_KEY=... \
    DEBVERSION=0acme1 \
    ./Dockerfile.build

Will build Debian/Ubuntu packages of the *MaxMind.com GeoIP2* free databases::

    $ find Dockerfile.out/ -type f | sort
    .../geoip2-database_0+20220502+203003-0acme1_amd64.buildinfo
    .../geoip2-database_0+20220502+203003-0acme1_amd64.changes
    .../geoip2-database_0+20220502+203003-0acme1.dsc
    .../geoip2-database_0+20220502+203003-0acme1.tar.gz
    .../geoip2-database-asn_0+20220502+203003-0acme1_all.deb
    .../geoip2-database-city_0+20220502+203003-0acme1_all.deb
    .../geoip2-database-country_0+20220502+203003-0acme1_all.deb

Those packages contain the ``GeoLite2-*.mmdb`` files. For instance::

    $ dpkg -L geoip2-database-country
    /.
    /usr
    /usr/share
    /usr/share/GeoIP2
    /usr/share/GeoIP2/GeoLite2-Country.mmdb
    /usr/share/doc
    /usr/share/doc/geoip2-database-country
    /usr/share/doc/geoip2-database-country/COPYRIGHT.txt
    /usr/share/doc/geoip2-database-country/LICENSE.txt
    /usr/share/doc/geoip2-database-country/README.txt
    /usr/share/doc/geoip2-database-country/changelog.Debian.gz


--------------------------------
How do you obtain a license key?
--------------------------------

https://dev.maxmind.com/geoip/geolite2-free-geolocation-data?lang=en


------------------------------
Why do you need a license key?
------------------------------

Previously, *Debian/Ubuntu* shipped with ``geoip-database`` packages.
But due to the changed license they couldn't anymore.

See: https://blog.maxmind.com/2019/12/significant-changes-to-accessing-and-using-geolite2-databases

  The California Consumer Privacy Act (CCPA) mandates that businesses
  honor valid "Do Not Sell" requests from California residents. In this
  context, complying with a valid request involves MaxMind removing IP
  addresses from the GeoLite2 data and communicating to GeoLite2 users
  that the IP addresses in question should (immediately) not be utilized
  for uses covered under the CCPA. Serving GeoLite2 database downloads on
  a public page simply does not allow us to communicate and honor valid
  "Do Not Sell" requests we receive from individuals.


-------
License
-------

See: https://www.maxmind.com/en/end-user-license-agreement

  The GeoLite2 end-user license agreement incorporates components of the
  Creative Commons Attribution-ShareAlike 4.0 International License. The
  attribution requirement may be met by including the following in all
  advertising and documentation mentioning features of or use of GeoLite2
  data. (See https://creativecommons.org/licenses/by-sa/4.0/ )


-------------------------------------------
Why the database change from .dat to .mmdb?
-------------------------------------------

* https://blog.maxmind.com/2018/01/discontinuation-of-the-geolite-legacy-databases
* https://blog.maxmind.com/2020/06/retirement-of-geoip-legacy-downloadable-databases-in-may-2022

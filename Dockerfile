FROM debian:bullseye

RUN sed -i -e 's@http://[^/]*@http://apt.osso.nl@' /etc/apt/sources.list
RUN apt-get -q update && apt-get -qqy dist-upgrade && \
    apt-get -qy install build-essential debhelper devscripts mmdb-bin

ARG upname upversion debepoch debversion
ENV fullversion=${debepoch}${upversion}-${debversion}

# Copy .cache sources and debian files
RUN mkdir -p /build/${upname}-${fullversion}/debian
WORKDIR /build/${upname}-${fullversion}
COPY .cache/GeoLite2-ASN.tar.gz .cache/GeoLite2-City.tar.gz \
     .cache/GeoLite2-Country.tar.gz ./
RUN tar -zxf GeoLite2-ASN.tar.gz && \
    tar -zxf GeoLite2-City.tar.gz && \
    tar -zxf GeoLite2-Country.tar.gz && \
    # check that copyright and license are the same for all
    test $(md5sum */COPYRIGHT.txt */LICENSE.txt | tee /dev/stderr | \
           awk '{print $1}' |sort -u | wc -l) -eq 2 && \
    mv */GeoLite2-*.mmdb . && \
    find . -name '*.txt' -exec mv -f '{}' . \; && \
    find . ! -name '*.mmdb' ! -name '*.txt' -delete && \
    find . | sort >&2
COPY changelog compat control rules \
     geoip2-database*.docs geoip2-database*.install \
     debian/
COPY source debian/source

# Set changelog version, build package
RUN sed -i -e "1s/([^)]*)/(${debepoch}${upversion}-${debversion})/" \
    debian/changelog
RUN cat debian/changelog >&2
RUN dpkg-buildpackage --build=source,all -us -uc -sa

# Install inside container and test
RUN ls /build
RUN dpkg -i /build/${upname}-*_${fullversion}_all.deb

# mmdblookup --file /usr/share/GeoIP2/GeoLite2-City.mmdb --ip IP city names en
RUN for ip_groningen in 217.21.192.1 217.21.207.11; do \
      val=$(mmdblookup --file /usr/share/GeoIP2/GeoLite2-City.mmdb \
            --ip $ip_groningen city names en | \
            sed -ne 's/^[[:blank:]]*"\([^"]*\)" <utf8_string>.*/\1/p') && \
      echo "lookup --ip $ip_groningen: got $val" && \
      test "$val" = Groningen; \
    done
RUN for ip_groningen in 217.21.192.1 217.21.207.11; do \
      val=$(mmdblookup --file /usr/share/GeoIP2/GeoLite2-City.mmdb \
            --ip $ip_groningen country iso_code | \
            sed -ne 's/^[[:blank:]]*"\([^"]*\)" <utf8_string>.*/\1/p') && \
      echo "lookup --ip $ip_groningen: got $val" && \
      test "$val" = NL; \
    done
# mmdblookup --file /usr/share/GeoIP2/GeoLite2-Country.mmdb --ip IP \
#   country iso_codes
RUN for ip_nl in 91.194.225.0 217.21.192.1; do \
      val=$(mmdblookup --file /usr/share/GeoIP2/GeoLite2-Country.mmdb \
            --ip $ip_nl country iso_code | \
            sed -ne 's/^[[:blank:]]*"\([^"]*\)" <utf8_string>.*/\1/p') && \
      echo "lookup --ip $ip_nl: got $val" && \
      test "$val" = NL; \
    done
# mmdblookup --file /usr/share/GeoIP2/GeoLite2-ASN.mmdb --ip IP
RUN val=$(mmdblookup --file /usr/share/GeoIP2/GeoLite2-ASN.mmdb --ip 1.1.1.1 |\
          tr '\n' ' ' | sed -e 's/<[^>]*>//g;s/[0-9]\+/&,/;s/[[:blank:]]//g');\
    echo "lookup --ip 1.1.1.1: got $val" && \
    test "$val" = '{"autonomous_system_number":13335,"autonomous_system_organization":"CLOUDFLARENET"}'
RUN val=$(mmdblookup --file /usr/share/GeoIP2/GeoLite2-ASN.mmdb --ip 8.8.8.8 |\
          tr '\n' ' ' | sed -e 's/<[^>]*>//g;s/[0-9]\+/&,/;s/[[:blank:]]//g');\
    echo "lookup --ip 8.8.8.8: got $val" && \
    test "$val" = '{"autonomous_system_number":15169,"autonomous_system_organization":"GOOGLE"}'

# Make files ready for export from container
RUN mkdir -p /dist/${upname}_${fullversion} && \
    mv /build/*${fullversion}*.* /dist/${upname}_${fullversion}/ && \
    cd / && find dist/${upname}_${fullversion} -type f >&2

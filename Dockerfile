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
RUN value=$(echo $(mmdblookup --file /usr/share/GeoIP2/GeoLite2-City.mmdb \
      --ip 217.21.207.11 city names en | sed -e 's/<.*>//;s/"//g') ) && \
    echo "[$value]" && test "$value" = Groningen && \
    value=$(echo $(mmdblookup --file /usr/share/GeoIP2/GeoLite2-City.mmdb \
      --ip 217.21.207.1 city names en | sed -e 's/<.*>//;s/"//g') ) && \
    echo "[$value]" && test "$value" = Amsterdam
RUN value=$(echo $(mmdblookup --file /usr/share/GeoIP2/GeoLite2-Country.mmdb \
      --ip 217.21.207.11 country names en | sed -e 's/<.*>//;s/"//g') ) && \
    echo "[$value]" && test "$value" = Netherlands && \
    value=$(echo $(mmdblookup --file /usr/share/GeoIP2/GeoLite2-Country.mmdb \
      --ip 217.21.207.1 country names en | sed -e 's/<.*>//;s/"//g') ) && \
    echo "[$value]" && test "$value" = Netherlands

# Make files ready for export from container
RUN mkdir -p /dist/${upname}_${fullversion} && \
    mv /build/*${fullversion}*.* /dist/${upname}_${fullversion}/ && \
    cd / && find dist/${upname}_${fullversion} -type f >&2

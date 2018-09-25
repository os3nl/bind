FROM alpine
RUN apk add --no-cache \
  alpine-sdk \
  bash \
  bsd-compat-headers \
  curl \
  gnupg \
  libcap-dev \
  libressl-dev \
  libxml2-dev \
  linux-headers \
  openssl \
  perl \
  perl-dev \
  perl-utils \
  json-c-dev

ENV ISC_PUB_KEY https://ftp.isc.org/isc/pgpkeys/codesign2017.txt
ENV BIND_TAR_URL https://www.isc.org/downloads/file/bind-9-12-2-p1/?version=tar-gz
ENV BIND_SHA_URL https://ftp.isc.org/isc/bind9/9.12.2-P1/bind-9.12.2-P1.tar.gz.sha512.asc
RUN curl --silent -o /tmp/isc.key $ISC_PUB_KEY
RUN curl --silent -o /tmp/bind.tgz $BIND_TAR_URL
RUN curl --silent -o /tmp/bind.sha512.asc $BIND_SHA_URL

RUN gpg --import /tmp/isc.key
RUN gpg --verify /tmp/bind.sha512.asc /tmp/bind.tgz

RUN cd /tmp; tar xfz /tmp/bind.tgz
RUN mv /tmp/bind-9* /bindsrc
WORKDIR /bindsrc
#RUN apk add --no-cache libtool

ENV OS3_SPECIFIC_PATH_01 /usr/local
ENV OS3_SPECIFIC_PATH_02 /usr/local/etc/bind
ENV OS3_SPECIFIC_PATH_03 /var/run
RUN ./configure \
		--prefix=$OS3_SPECIFIC_PATH_01 \
		--sysconfdir=$OS3_SPECIFIC_PATH_02 \
		--localstatedir=$OS3_SPECIFIC_PATH_03 \
		--with-openssl=/usr \
		--enable-linux-caps \
		--with-libxml2 \
		--with-libjson \
		--enable-threads \
		--enable-filter-aaaa \
		--enable-ipv6 \
		--enable-shared \
		--enable-static \
		--with-libtool \
		--with-randomdev=/dev/random \
		--mandir=/usr/share/man \
		--infodir=/usr/share/info \
    1> /dev/null
RUN make 1> /dev/null
RUN make install 1> /dev/null

# linking config to logical places
RUN ln -s $OS3_SPECIFIC_PATH_02 /etc/bind

#man named.conf|grep named.conf|tail -1
#       /etc/named.conf
COPY named.conf /etc/
COPY named.local /etc
RUN ln -s /etc/named.conf $OS3_SPECIFIC_PATH_02/named.conf
RUN ln -s /etc/named.local $OS3_SPECIFIC_PATH_02/named.local

# 3.3 Resolving
RUN curl --silent -o $OS3_SPECIFIC_PATH_02/named.cache \
  ftp://ftp.rs.internic.net/domain/named.cache

RUN named-checkconf /usr/local/etc/bind/named.conf \
  || (echo named.conf has an error! && exit 1)

EXPOSE 53

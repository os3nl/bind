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

# 3.1 Main Configuration
#man named.conf|grep named.conf|tail -1
#       /etc/named.conf
COPY named.conf /etc/
RUN ln -s /etc/named.conf $OS3_SPECIFIC_PATH_02/named.conf

# 3.2 Root Servers
RUN curl --silent -o $OS3_SPECIFIC_PATH_02/named.cache \
  ftp://ftp.rs.internic.net/domain/named.cache

# 3.3 Resolving
COPY named.local /etc
RUN ln -s /etc/named.local $OS3_SPECIFIC_PATH_02/named.local

# 3.4 Testing
RUN named-checkconf /usr/local/etc/bind/named.conf \
  || (echo named.conf has an error! && exit 1)


EXPOSE 53
# 4 Running and Improving the Name Server
ENTRYPOINT ["/usr/local/sbin/named", "-d2"]
# -g = Run the server in the foreground and force all logging to stderr. src:https://linux.die.net/man/8/named
# we could also use -f
CMD ["-g"]

# assignment: write debug information to a log file
# but in docker, you don't do this, docker handles it,
# so I throw it to stdout
#RUN ln -s /dev/stdout /var/log/named.log


# Q6
# inspired by tecadmin.net/configure-rndc-for-bind9
# The following is for illustrative purpose, it is part of the assignment,
# you should NEVER put private key files in your container!
# rndc-confgen --help 2>&1|grep generate
#  -a:            generate just the key clause and write it to keyfile (/usr/local/etc/bind/rndc.key)
RUN rndc-confgen -r /dev/urandom -a

# Now we construct the rndc.conf
WORKDIR $OS3_SPECIFIC_PATH_02
RUN cat rndc.key > rndc.conf; \
  echo 'options { default-port 953; default-key "rndc-key"; default-server 127.0.0.1;};' >> rndc.conf
# and update the config
# https://support.plesk.com/hc/en-us/articles/115003691334-DNS-does-not-propage-rndc-connection-to-remote-host-closed
RUN cat rndc.key >> named.conf; \
  echo 'controls { inet 127.0.0.1 port 953 allow {127.0.0.1; 172/8; 0/0;} keys {"rndc-key";}; };' >> named.conf
EXPOSE 953

# Q7
COPY entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]


### lab 4 DNS 2 ###

### START block_that_does_nothing
RUN apk add --no-cache sipcalc
ENV FIRST3OCT 145.100.111
ENV LASTOCTET 0
ENV SERVER_RANGE $FIRST3OCT.$LASTOCTET/28
RUN sipcalc $SERVER_RANGE|grep range
#Network range     - 145.100.111.0 - 145.100.111.15
#Usable range      - 145.100.111.1 - 145.100.111.14

# The following code generates a forward lookup zone assuming a /28 range
ENV MYZONEDB $OS3_SPECIFIC_PATH_02/myzone.db
RUN echo "subnet-network-ip IN A $FIRST3OCT.$LASTOCTET" > $MYZONEDB
SHELL ["/bin/bash", "-c"]
RUN for i in {1..14}; do echo "host$i IN A $FIRST3OCT."$((LASTOCTET + i)) >> $MYZONEDB; done
RUN echo "subnet-broadc IN A $FIRST3OCT."$((LASTOCTET + 15)) >> $MYZONEDB
### END block_that_does_nothing


# We see the first three octets in reverse order:
RUN echo 'zone "111.100.145.in-addr.arpa" IN { type master; file "myzone.conf";};' \
  >> $OS3_SPECIFIC_PATH_02/named.conf

RUN echo 'zone "mypraczone" IN { type master; file "myprac.conf";};' \
  >> $OS3_SPECIFIC_PATH_02/named.conf

COPY myzone.conf $OS3_SPECIFIC_PATH_02/
ENTRYPOINT ["/usr/local/sbin/named","-f","-p","53"]
CMD ["-4"]

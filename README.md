# OS3.nl CIA Lab3 Bind DNS

Also available on [docker hub](https://hub.docker.com/r/os3nl/bind).

WARNING this is a school assignment, do not run this otherwise.

```
docker run --rm -d \
  --name bind \
  -p 145.100.104.117:53:53/tcp \
  -p 145.100.104.117:53:53/udp \
  os3nl/bind
```

named-checkconf /etc/named.conf

## Guides
+ https://www.digitalocean.com/community/tutorials/how-to-configure-bind-as-an-authoritative-only-dns-server-on-ubuntu-14-04
+ https://devops.profitbricks.com/tutorials/configure-authoritative-name-server-using-bind-on-ubuntu/

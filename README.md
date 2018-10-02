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
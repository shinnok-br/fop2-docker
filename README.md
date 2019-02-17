# Container of FOP2 for Asterisk/SNEP

All the configurations of FOP2 in a container!

Manual start:

```bash
docker run -d --restart=always --name fop2 -p 4445:4445 -p 8081:8081 -v fop2-docker:/usr/local/fop2 shinnok/fop2-docker
```

Docker Compose start:

```bash
docker-compose up -d

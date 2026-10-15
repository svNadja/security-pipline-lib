#pfade erstellen
mkdir -p openbao/config openbao/data openbao/logs
cd openbao

$ make dev

#Running OpenBao in Server Mode
docker run \
    --name openbao \
    --detach \
    --volume /openbao/config:/openbao/config \
    --publish 8200:8200 \
    openbao/openbao


$ docker logs -f openbao-dev
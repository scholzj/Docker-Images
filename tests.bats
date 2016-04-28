#!/usr/bin/env bats

IMAGE="ecmi/fixml"
VERSION="prod"

setup() {
    export QPID_SSL_CERT_DB=sql:./tests/
    export QPID_SSL_CERT_PASSWORD_FILE=./tests/pwdfile
    export QPID_SSL_CERT_NAME=ABCFR_ABCFRALMMACC1
}

teardown() {
    sudo docker stop $cont
    sudo docker rm $cont
}

tcpPort() {
    sudo docker port $cont 5672 | cut -f 2 -d ":"
}

sslPort() {
    sudo docker port $cont 5671 | cut -f 2 -d ":"
}

@test "Test broadcasts with AMQP 0-10" {
    cont=$(sudo docker run -P -d $IMAGE:$VERSION)
    tcp=$(tcpPort)
    ssl=$(sslPort)
    sleep 5 # give the image time to start

    run qpid-send -b ecag-fixml-dev1:$tcp -a "broadcast/broadcast.ABCFR.TradeConfirmation; { node: { type: topic}, assert: never, create: never }" -m 1 --durable --content-size 1024
    [ "$status" -eq "0" ]

    run qpid-receive -b ecag-fixml-dev1:$ssl --connection-options "{ transport: ssl, sasl_mechanism: EXTERNAL }" -a "broadcast.ABCFR_ABCFRALMMACC1.TradeConfirmation; { node: { type: queue}, assert: never, create: never }" -m 1 --timeout 5
    [ "$status" -eq "0" ]
}

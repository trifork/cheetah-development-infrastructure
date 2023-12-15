```sh
docker run -it --rm --user root --network=cheetah-infrastructure -v "${PWD}/backup:/tmp" --entrypoint "/bin/bash" quay.io/strimzi/kafka:0.38.0-kafka-3.6.0 -c 'bin/kafka-console-consumer.sh --topic test-index-ktd-json-no-compression --from-beginning --bootstrap-server kafka:19093 --property print.key=true > /tmp/test-index-ktd-no-compression3.txt'

docker run -it --rm --user root --network=cheetah-infrastructure -v "${PWD}/backup:/tmp" --entrypoint "/bin/bash" quay.io/strimzi/kafka:0.38.0-kafka-3.6.0 -c 'bin/kafka-console-producer.sh --topic test-index-ktd-json-no-compression --bootstrap-server kafka:19093 --property parse.key=true < /tmp/test-index-ktd-no-compression3.txt'

wc -l backup/test-index-ktd-no-compression3.txt | awk '{printf "%'\''d\n", $1}'


```
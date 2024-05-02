# Utils for testing

## Docker scout

```sh
docker compose images --format 'json' | jq 'map(.Repository + ":" + .Tag) | .[]' | xargs -I '{}' docker scout cves --only-fixed --format only-packages {}
docker compose images --format 'json' | jq 'map(.Repository + ":" + .Tag) | .[]' | xargs -I '{}' docker scout quickview {}
```

## Profiling

```sh
# Get MemUsage for all running containers
docker compose stats --no-stream | awk 'NR>1 {print $4}' | numfmt --from=auto --suffix=B | awk '{sum+=$1}END{print sum}' | numfmt --to=iec
# Image size
docker compose images | awk 'NR>1 {print $5}' | numfmt --from=auto --suffix=B | awk '{sum+=$1}END{print sum}' | numfmt --to=iec
```

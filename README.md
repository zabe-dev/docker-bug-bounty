Dockerized bug bounty tools.

```sh
docker compose -f /path/to/compose.yaml run --rm docker-bug-bounty
```

Update SecLists:

```sh
docker compose run --rm docker-bug-bounty \
  bash -lc 'git -C /opt/wordlists/SecLists pull --ff-only'
```

Dockerized bug bounty tools.

`dbb` runs tools in a temporary container. Only the host `./output` directory
is mounted into the container as `/mnt/output`; other files remain in the
container.

```sh
dbb <tool> [options]
```

Examples:

```sh
dbb nmap -sV example.com
dbb ffuf -u https://example.com/FUZZ \
  -w /opt/wordlists/SecLists/Discovery/Web-Content/common.txt
dbb dirsearch -u https://example.com \
  -w /opt/wordlists/SecLists/Discovery/Web-Content/common.txt
```

SecLists is stored in a persistent Docker volume at `/opt/wordlists/SecLists`.
Update it without rebuilding the image:

```sh
dbb bash -lc 'git -C /opt/wordlists/SecLists pull --ff-only'
```

Wayback URL analysis. Results written under `/mnt/output` appear under
`./output` in the directory where the command is run:

```sh
dbb wayplus -d example.com -output /mnt/output/example
```

Add `-c 3` to crawl the live site with Katana:

```sh
dbb wayplus -d example.com -c 3 -output /mnt/output/example
```

The analyzer combines Waymore, waybackurls, and optional Katana output, then
writes classified URL lists, decoded JWTs, and archived compressed-file URLs
to the output directory.

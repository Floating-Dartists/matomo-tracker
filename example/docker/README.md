Use this `Dockerfile` to build a preconfigured Matomo instance for testing.

1. Build & Tag:
```bash
docker build . -t matomo-tracker-example
```

2. Run
```bash
docker run --name=matomo-tracker-example -p 8765:80 matomo-tracker-example
```

You can now access the dashboard at http://localhost:8765/index.php.
The username and password are both `matomo`.
The Tacking API is at http://localhost:8765/matomo.php, the site id is `1`.
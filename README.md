# docker-oe117-wsa



## Docker commands

### Build the docker image

```bash
docker build -t oe117-wsa:0.1 -t oe117-wsa:latest .
```

### Run the container

```bash
docker run -it --rm --name oe117-wsa -p 80:80 oe117-wsa:latest
```

### Run bash in the container

```bash
docker run -it --rm --name oe117-wsa -p 80:80 oe117-wsa:latest bash
```

### Exec bash in the running container

```bash
docker exec -it oe117-wsa bash
```

### Stop the container

```bash
docker stop oe117-wsa
```

### Clean the container

```bash
docker rm oe117-wsa
```

- - -

Please note that this project is released with a [Contributor Code of Conduct](code-of-conduct.md). By participating in this project you agree to abide by its terms.

### Building Docker containers for local testing

To build:

    docker build -f Dockerfile.base-spack -t <name>:<version> --target dev --no-cache --progress=plain .

To run:

    docker run -it --rm <name>:<version>

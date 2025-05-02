FROM python:3.13-alpine

WORKDIR /app

# Create the files that will respond to both "/" and "/${4}"
RUN echo "OK" > index.html && mkdir -p up && echo "OK" > up/index.html

EXPOSE 3003

# Force run as root to avoid permission problems
USER root

# CMD ["python", "-m", "http.server", "3003", "--bind", "0.0.0.0", "--directory", "/app"]
CMD ["echo", "Starting server on port 3003", "&&", "python", "-m", "http.server", "3003", "--bind", "0.0.0.0", "--directory", "/app"]

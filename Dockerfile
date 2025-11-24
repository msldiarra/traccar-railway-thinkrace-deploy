# ---------- Stage 1: build your custom Traccar ----------
FROM eclipse-temurin:17-jdk-alpine AS build

WORKDIR /build

# We need git
RUN apk add --no-cache git

# ---- CONFIGURABLE ARGS ----
ARG TRACCAR_REPO=https://github.com/msldiarra/traccar-thinkrace.git

# Clone your fork into /build/src
RUN git clone "$TRACCAR_REPO" src

# Move into the repo directory
WORKDIR /build/src

# Remove project gradle.properties if it has host-specific stuff (optional safety)
RUN rm -f gradle.properties || true

# Ensure Gradle wrapper is executable
RUN chmod +x gradlew

# Build server + dependencies (jar goes to target/, libs to target/lib)
RUN ./gradlew clean assemble --no-daemon -x test -x check

# After this, we expect:
#   /build/src/target/<something>.jar
#   /build/src/target/lib/*.jar


# ---------- Stage 2: runtime image ----------
FROM eclipse-temurin:17-jre-alpine

WORKDIR /opt/traccar

# For envsubst in entrypoint.sh
RUN apk add --no-cache gettext

# Standard Traccar directories
RUN mkdir -p conf logs data lib

# Config template + entrypoint from this repo
COPY traccar.xml.template conf/traccar.xml.template
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Copy built JAR + libs from build stage
COPY --from=build /build/src/target/*.jar ./tracker-server.jar
COPY --from=build /build/src/target/lib ./lib

# NEW: copy Liquibase schema directory
COPY --from=build /build/src/schema ./schema

ENTRYPOINT ["/entrypoint.sh"]


# ---------- Stage 1: build your custom Traccar ----------
FROM eclipse-temurin:17-jdk-alpine AS build

WORKDIR /build

# We need git and bash-ish tools
RUN apk add --no-cache git

# ---- CONFIGURABLE ARGS ----
# URL of your traccar fork (Repo A)
ARG TRACCAR_REPO=https://github.com/msldiarra/traccar-thinkrace.git

# Clone your fork
RUN git clone "$TRACCAR_REPO" src

# IMPORTANT: remove any host-specific gradle.properties that
# might contain org.gradle.java.home=/usr/lib/jvm/... from your host
RUN rm -f gradle.properties

# Build server + copyDependencies (no tests/checkstyle)
RUN ./gradlew clean copyDependencies --no-daemon -x test -x check

# After this, we expect:
#  /build/src/target/tracker-server.jar
#  /build/src/target/lib/*.jar


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
COPY --from=build /build/src/target/tracker-server.jar ./tracker-server.jar
COPY --from=build /build/src/target/lib ./lib

ENTRYPOINT ["/entrypoint.sh"]

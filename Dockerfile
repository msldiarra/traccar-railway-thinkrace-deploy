# ---------- Stage 1: build your custom Traccar ----------
FROM eclipse-temurin:17-jdk-alpine AS build

WORKDIR /build

# We need git
RUN apk add --no-cache git

# ---- CONFIGURABLE ARGS ----
ARG TRACCAR_REPO=https://github.com/msldiarra/traccar-thinkrace.git

ARG CACHE_BUST=10
RUN echo "Cache bust = $CACHE_BUST"
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
# or :latest, but 6.10 matches your build
FROM traccar/traccar:6.10

# (optional) we still want envsubst in our custom entrypoint
RUN apk add --no-cache gettext dos2unix

WORKDIR /opt/traccar

# Our config template + entrypoint from THIS repo
COPY traccar.xml.template /opt/traccar/conf/traccar.xml.template
COPY entrypoint.sh /entrypoint.sh
RUN dos2unix /entrypoint.sh && chmod +x /entrypoint.sh

# Override Traccar server JAR with your custom build
COPY --from=build /build/src/target/*.jar /opt/traccar/tracker-server.jar

# (optional but clean) override lib directory as well,
# since assemble already populated target/lib with 6.10 deps
COPY --from=build /build/src/target/lib /opt/traccar/lib

ENTRYPOINT ["/entrypoint.sh"]



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

# syntax=docker/dockerfile:1

FROM dart:stable AS build

WORKDIR /app

# Copy only the server and the local patched dependency that the workspace uses.
COPY third_party ./third_party
COPY motaz_app_server ./motaz_app_server

WORKDIR /app/motaz_app_server

# The repository is a Dart/Flutter workspace, but this image builds the backend
# only. Removing the workspace marker avoids requiring a Flutter SDK inside the
# server image while preserving the patched postgres override used by the repo.
RUN sed -i 's/\r$//' pubspec.yaml \
  && sed -i '/^resolution:[[:space:]]*workspace[[:space:]]*$/d' pubspec.yaml \
  && printf '\n# Docker backend build override.\ndependency_overrides:\n  postgres:\n    path: ../third_party/postgres-3.5.9-patched\n' >> pubspec.yaml

RUN dart pub get
RUN dart compile exe bin/main.dart -o /app/server

FROM alpine:3.20

RUN apk add --no-cache ca-certificates gettext \
  && addgroup -S app \
  && adduser -S app -G app

WORKDIR /app

ENV runmode=production
ENV serverid=default
ENV logging=normal
ENV role=monolith

COPY --from=build /runtime/ /
COPY --from=build /app/server ./server
COPY --from=build /app/motaz_app_server/config/ ./config/
COPY --from=build /app/motaz_app_server/web/ ./web/
COPY --from=build /app/motaz_app_server/migrations/ ./migrations/
RUN mkdir -p ./lib/src/generated
COPY --from=build /app/motaz_app_server/lib/src/generated/protocol.yaml ./lib/src/generated/protocol.yaml
COPY motaz_app_server/docker/entrypoint.sh /usr/local/bin/motaz-server-entrypoint

RUN sed -i 's/\r$//' /usr/local/bin/motaz-server-entrypoint \
  && chmod +x /usr/local/bin/motaz-server-entrypoint \
  && chown -R app:app /app

USER app

EXPOSE 8080 8081 8082

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD sh -c 'wget -q -O /dev/null "http://127.0.0.1:${PORT:-8080}/" || exit 1'

ENTRYPOINT ["/usr/local/bin/motaz-server-entrypoint"]
CMD ["--apply-migrations"]

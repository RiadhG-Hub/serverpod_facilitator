FROM dart:stable AS build
WORKDIR /app
COPY . .
RUN dart pub get
RUN dart compile exe bin/main.dart -o bin/main

FROM debian:bookworm-slim
COPY --from=build /app/bin/main /app/bin/main
CMD ["/app/bin/main"]

FROM eclipse-temurin:21-jre-jammy

WORKDIR /app

RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

RUN curl -L \
  https://download.geysermc.org/v2/projects/geyser/versions/latest/builds/latest/downloads/standalone \
  -o Geyser.jar

EXPOSE 19132/udp

CMD ["java", "-jar", "Geyser.jar"]
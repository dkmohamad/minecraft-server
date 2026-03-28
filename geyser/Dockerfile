FROM eclipse-temurin:21-jre

RUN mkdir -p /opt/geyser /data

ADD https://download.geysermc.org/v2/projects/geyser/versions/latest/builds/latest/downloads/standalone /opt/geyser/Geyser.jar

WORKDIR /data

EXPOSE 19132/udp

CMD ["java", "-Xms256M", "-Xmx512M", "-jar", "/opt/geyser/Geyser.jar"]

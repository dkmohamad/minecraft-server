# Pinned for the party. Base image + Geyser build frozen to the verified-working
# set so a rebuild can't pull a newer Geyser unintentionally.
# 2026-06-20: bumped Geyser 2.9.5-b1107 -> 2.10.1-b1172 because b1107 topped out at
# Bedrock 26.10, but the party's iPad client is on 26.21 ("Outdated Geyser proxy").
FROM eclipse-temurin:21-jre@sha256:9d4453b48613404e1fa6e5e7eabc687ea57edfb8a1ad413956c5168f84b66af9

RUN mkdir -p /opt/geyser /data

# Geyser 2.10.1 build 1172 (was: 2.9.5/1107)
ADD https://download.geysermc.org/v2/projects/geyser/versions/2.10.1/builds/1172/downloads/standalone /opt/geyser/Geyser.jar

WORKDIR /data

EXPOSE 19132/udp

CMD ["java", "-Xms256M", "-Xmx512M", "-jar", "/opt/geyser/Geyser.jar"]

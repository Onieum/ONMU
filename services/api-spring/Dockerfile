FROM eclipse-temurin:21-jdk AS build

WORKDIR /workspace

RUN apt-get update \
  && apt-get install -y --no-install-recommends unzip \
  && rm -rf /var/lib/apt/lists/*

COPY .mvn/ .mvn/
COPY mvnw pom.xml ./
RUN chmod +x mvnw

COPY src src

RUN ./mvnw -q -DskipTests package \
  && JAR_PATH="$(find target -maxdepth 1 -type f -name '*.jar' ! -name '*.jar.original' | head -n 1)" \
  && test -n "$JAR_PATH" \
  && cp "$JAR_PATH" /workspace/onmu-api-spring.jar

FROM eclipse-temurin:21-jre

WORKDIR /app

RUN addgroup --system onmu && adduser --system --ingroup onmu onmu

COPY --from=build /workspace/onmu-api-spring.jar /app/onmu-api-spring.jar

EXPOSE 8080

USER onmu

ENTRYPOINT ["java", "-jar", "/app/onmu-api-spring.jar"]

FROM eclipse-temurin:21-jdk AS build

WORKDIR /workspace

RUN apt-get update \
  && apt-get install -y --no-install-recommends curl unzip \
  && rm -rf /var/lib/apt/lists/*

ARG APPINSIGHTS_AGENT_VERSION=3.7.8

COPY .mvn/ .mvn/
COPY mvnw pom.xml ./
RUN chmod +x mvnw

COPY src src

RUN ./mvnw -q -DskipTests package \
  && JAR_PATH="$(find target -maxdepth 1 -type f -name '*.jar' ! -name '*.jar.original' | head -n 1)" \
  && test -n "$JAR_PATH" \
  && cp "$JAR_PATH" /workspace/onmu-api-spring.jar

RUN curl -fsSL \
    "https://github.com/microsoft/ApplicationInsights-Java/releases/download/${APPINSIGHTS_AGENT_VERSION}/applicationinsights-agent-${APPINSIGHTS_AGENT_VERSION}.jar" \
    -o /workspace/applicationinsights-agent.jar

FROM eclipse-temurin:21-jre

WORKDIR /app

RUN addgroup --system onmu && adduser --system --ingroup onmu onmu

COPY --from=build /workspace/onmu-api-spring.jar /app/onmu-api-spring.jar
COPY --from=build /workspace/applicationinsights-agent.jar /app/applicationinsights-agent.jar

ENV JAVA_TOOL_OPTIONS="-javaagent:/app/applicationinsights-agent.jar"

EXPOSE 8080

USER onmu

ENTRYPOINT ["java", "-jar", "/app/onmu-api-spring.jar"]

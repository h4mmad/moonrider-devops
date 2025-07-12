# Multi-stage Dockerfile for Spring Boot Application

# Stage 1: Build the application
FROM maven:3.8.6-openjdk-11-slim AS builder

# Set working directory
WORKDIR /app

# Copy pom.xml and download dependencies
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copy source code
COPY src ./src

# Build the application
RUN mvn clean package -DskipTests

# Stage 2: Runtime image
FROM openjdk:11-jre-slim

# Create non-root user for security
RUN groupadd -r spring && useradd -r -g spring spring

# Set working directory
WORKDIR /app

# Copy the built JAR from builder stage
COPY --from=builder /app/target/*.jar app.jar

# Create directory for logs
RUN mkdir -p /app/logs && chown -R spring:spring /app

# Switch to non-root user
USER spring

# Expose port
EXPOSE 9191

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:9191/actuator/health || exit 1

# JVM options for production
ENV JAVA_OPTS="-Xms512m -Xmx1024m -XX:+UseG1GC -XX:+UseContainerSupport"

# Run the application
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"] 
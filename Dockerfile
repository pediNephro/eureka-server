# Multi-stage build for Spring Boot Eureka Server service
FROM maven:3.9.0-eclipse-temurin-17 AS build

# Set working directory
WORKDIR /app

# Copy pom.xml and download dependencies (for better caching)
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copy source code
COPY src ./src

# Build the application
RUN mvn clean package -DskipTests

# Runtime stage
FROM eclipse-temurin:17-jre

# Add metadata labels
LABEL maintainer="PediNephro Team" \
      version="1.0" \
      description="Eureka Server Service"

# Create non-root user
RUN groupadd -r eureka && useradd -r -g eureka eureka

# Set working directory
WORKDIR /app

# Copy the JAR file from build stage
COPY --from=build /app/target/*.jar app.jar

# Change ownership to non-root user
RUN chown -R eureka:eureka /app

# Switch to non-root user
USER eureka

# Expose port
EXPOSE 8761

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8761/actuator/health || exit 1

# Run the application
ENTRYPOINT ["java", "-jar", "app.jar"]
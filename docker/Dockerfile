# syntax=docker/dockerfile:1

# Stage 1: Build stage
FROM node:22-alpine AS build

# Security updates
RUN apk update && apk upgrade && apk add --no-cache dumb-init

# Set working directory
WORKDIR /usr/src/app

# Copy dependency files first for better caching
COPY package.json package-lock.json ./

# Install dependencies with cache optimization
RUN --mount=type=cache,target=/root/.npm \
    npm ci --only=production && \
    npm cache clean --force

# Copy application source
COPY . .

# Build Angular application first
WORKDIR /usr/src/app/angular-app
RUN npm ci && npm run build

# Go back to the root directory and run the main build command
WORKDIR /usr/src/app
RUN npm run build

# Stage 2: Production-ready stage
FROM node:22-alpine AS production

# Install security updates and dumb-init as root
RUN apk update && apk upgrade && apk add --no-cache dumb-init

# Set the working directory
WORKDIR /usr/src/foodme

# Copy only production files
COPY --from=build /usr/src/app/dist ./dist
COPY --from=build /usr/src/app/node_modules ./node_modules
COPY --from=build /usr/src/app/package.json ./

# Change ownership of the application files to the existing node user
RUN chown -R node:node /usr/src/foodme

# Switch to non-root user (node user already exists in node:alpine)
USER node

# Expose the port your app runs on
EXPOSE 3000

# Command to run your application
ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "dist/server/start.js"]
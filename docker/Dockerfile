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

# Build Angular application
WORKDIR /usr/src/app/angular-app
RUN npm ci && npm run build

# Build the application
RUN npm run build

# Stage 2: Production-ready stage
FROM node:22-alpine AS production

RUN apk add --no-cache dumb-init

WORKDIR /usr/src/foodme

USER node

# Set the working directory inside the container
WORKDIR /usr/src/foodme

# Copy only production files
COPY --from=build /usr/src/app/dist ./dist
COPY --from=build /usr/src/app/node_modules ./node_modules
COPY --from=build /usr/src/app/package.json ./

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S node -u 1001
USER node

# Expose the port your app runs on
EXPOSE 3000

# Command to run your application
ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "dist/server.js"]
# syntax=docker/dockerfile:1

# Stage 1: Build stage
FROM node:22 AS build

# Set the working directory inside the container
WORKDIR /usr/src/app

# Copy package.json and package-lock.json to the working directory
COPY package.json package-lock.json ./

# Copy the rest of the application code to the working directory
COPY . /usr/src/app

# Download dependencies as a separate step to take advantage of Docker's caching.
# Leverage a cache mount to /root/.npm to speed up subsequent builds.
# Use npm ci for faster, reliable, reproducible builds.
# Install all dependencies (including dev) for the build stage
RUN --mount=type=bind,source=package.json,target=package.json \
    --mount=type=bind,source=package-lock.json,target=package-lock.json \
    --mount=type=cache,target=/root/.npm \
    npm ci

# Install Angular dependencies
WORKDIR /usr/src/app/angular-app
RUN npm ci
WORKDIR /usr/src/app

# Build the application
RUN npm run build

# Stage 2: Production-ready stage
FROM node:22-slim

USER node
ENV NODE_ENV=production

# Set the working directory inside the container
WORKDIR /foodme

# Copy package.json first to install production dependencies
COPY --from=build /usr/src/app/package.json ./package.json
COPY --from=build /usr/src/app/package-lock.json ./package-lock.json

# Install only production dependencies
RUN npm ci --omit=dev && npm cache clean --force

# Copy built artifacts from the previous stage
COPY --from=build /usr/src/app/dist/ ./app

# Expose the port your app runs on
EXPOSE 3000

# Command to run your application
ENTRYPOINT ["node", "app/server/start.js"]
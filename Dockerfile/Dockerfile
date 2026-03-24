# =============================================================================
# STAGE 1 - builder
# Compile/build the application in a full image
# =============================================================================
FROM node:22-alpine AS builder

WORKDIR /app

# Copy dependency files first to leverage layer cache
# (only invalidated when package.json changes)
COPY package*.json ./

# Install ALL dependencies (including devDependencies for build)
RUN npm install

# Copy source code and build
COPY src/ ./src/
RUN npm run build


# =============================================================================
# STAGE 2 - production
# Final image: only production artifacts, no build tools or dev dependencies
# =============================================================================
FROM node:22-alpine AS production

# Security: run as non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# Copy only production dependency definitions
COPY package*.json ./

# Install only production dependencies
RUN npm install --omit=dev && \
    npm cache clean --force

# Copy compiled output from builder stage
COPY --from=builder /app/dist ./dist

# Switch to non-root user
USER appuser

# Document the port (does not publish it — docker-compose handles that)
EXPOSE 3000

# Use exec form to properly handle signals (PID 1)
CMD ["node", "dist/index.js"]

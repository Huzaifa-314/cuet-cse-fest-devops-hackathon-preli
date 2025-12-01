# Stage 1: Build stage
FROM node:18-alpine AS builder

WORKDIR /app

# Copy package files for dependency installation (optimize layer caching)
COPY package.json package-lock.json* ./

# Install all dependencies (including devDependencies for building)
# Use npm install if package-lock.json doesn't exist, otherwise use npm ci
RUN if [ -f package-lock.json ]; then npm ci; else npm install; fi

# Copy TypeScript config
COPY tsconfig.json ./

# Copy source files
COPY src ./src

# Build TypeScript to JavaScript
RUN npm run build && \
    # Remove source files and dev dependencies to reduce image size
    rm -rf src node_modules && \
    npm ci --only=production

# Stage 2: Production runtime stage
FROM node:18-alpine AS production

WORKDIR /app

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Copy package files
COPY package.json package-lock.json* ./

# Copy built files and production node_modules from builder stage
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules

# Change ownership to non-root user
RUN chown -R nodejs:nodejs /app

# Switch to non-root user
USER nodejs

# Set environment variables
ENV NODE_ENV=production

# Expose port
EXPOSE 3847

# Start the application
CMD ["npm", "start"]


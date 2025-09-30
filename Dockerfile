# Multi-stage build
FROM node:18-alpine AS builder

# Build client
WORKDIR /app/client
COPY client/package*.json ./
RUN npm ci --only=production
COPY client/ ./
RUN npm run build

# Production image
FROM node:18-alpine

# Install PM2 globally
RUN npm install -g pm2

# Create app directory
WORKDIR /app

# Create directories for data and uploads
RUN mkdir -p /app/data /app/uploads

# Copy server files
COPY server/package*.json ./
RUN npm ci --only=production

COPY server/ ./

# Copy built client
COPY --from=builder /app/client/build ./public

# Copy production env
COPY .env.production .env

# Create PM2 ecosystem file
RUN echo 'module.exports = { \
  apps: [{ \
    name: "soulful-roots", \
    script: "index.js", \
    instances: 1, \
    exec_mode: "cluster", \
    env: { \
      NODE_ENV: "production", \
      PORT: 5001 \
    } \
  }] \
}' > ecosystem.config.js

# Expose port
EXPOSE 5001

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:5001/health || exit 1

# Start with PM2
CMD ["pm2-runtime", "start", "ecosystem.config.js"]
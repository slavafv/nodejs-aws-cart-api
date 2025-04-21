# Build stage
FROM node:20-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install all dependencies (including dev dependencies for build)
RUN npm ci

# Copy source code
COPY . .

# Build the application
RUN npm run build

# Remove dev dependencies for production
RUN npm prune --omit=dev

# Production stage
FROM node:20-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install only production dependencies
RUN npm ci --only=production

# Copy built application from builder stage
COPY --from=builder /app/dist ./dist
# COPY --from=builder /app/node_modules ./node_modules

# Create a non-root user
USER node

# Set production environment
ENV NODE_ENV=production

# Expose the port the app runs on
EXPOSE 4000

# Start the application using the production script
CMD ["node", "dist/main.js"]
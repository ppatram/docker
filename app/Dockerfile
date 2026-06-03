FROM node:22-alpine
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm ci --ignore-scripts --omit=dev
COPY server.js .
USER 1000
EXPOSE 8080
CMD ["node", "server.js"]

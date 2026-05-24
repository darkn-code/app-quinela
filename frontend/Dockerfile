FROM node:20-alpine

WORKDIR /app

EXPOSE 5173

# This image is ready for a React + Vite app.
# Until package.json exists, docker-compose keeps the container alive with a clear message.
CMD ["sh", "-c", "if [ -f package.json ]; then npm install && npm run dev -- --host 0.0.0.0; else echo 'Frontend React + Vite no inicializado todavia.' && sleep infinity; fi"]

FROM node:20.19-alpine AS build-stage

WORKDIR /app

ARG VITE_API_URL
ENV VITE_API_URL=$VITE_API_URL

COPY package*.json ./
RUN --mount=type=cache,id=npm-cache,target=/root/.npm npm ci

COPY . .
RUN npm run build

FROM node:20.19-alpine AS production-stage

WORKDIR /app

RUN npm install -g serve

COPY --from=build-stage /app/dist ./dist

EXPOSE 3000

CMD ["serve", "-s", "dist", "-l", "3000"]
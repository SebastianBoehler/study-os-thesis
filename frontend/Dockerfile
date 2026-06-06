FROM node:20-alpine AS build

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci

COPY . .
RUN npm run build

FROM nginx:1.27-alpine AS runtime

COPY nginx.conf /etc/nginx/templates/default.conf.template
COPY docker-entrypoint.d /docker-entrypoint.d
COPY --from=build /app/dist /usr/share/nginx/html

ENV API_BASE_URL=""

EXPOSE 8080

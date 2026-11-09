# ── Stage 1: Build da Aplicação Flutter Web ──────────────────────────────────
FROM ghcr.io/cirruslabs/flutter:3.24.5 AS build

WORKDIR /app

RUN flutter config --enable-web

COPY pubspec.yaml ./
RUN flutter pub get

COPY . .

RUN flutter create . --platforms=web
RUN flutter build web --release --no-tree-shake-icons

# ── Stage 2: Nginx Web Server de Alta Performance ────────────────────────────
FROM nginx:alpine

# Remove configuração padrão
RUN rm -rf /usr/share/nginx/html/* /etc/nginx/conf.d/default.conf

# Copia a configuração customizada do Nginx com suporte a SPA e MIME types corretos
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copia os artefatos compilados do Flutter Web
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]

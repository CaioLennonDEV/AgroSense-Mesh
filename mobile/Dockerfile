FROM ghcr.io/cirruslabs/flutter:3.24.5

WORKDIR /app

# 1. Habilita compilação para Web
RUN flutter config --enable-web

# 2. Copia o manifesto de dependências
COPY pubspec.yaml ./
RUN flutter pub get

# 3. Copia todo o código-fonte
COPY . .

# 4. Garante a integridade dos artefatos da plataforma Web
RUN flutter create . --platforms=web

EXPOSE 8080

CMD ["flutter", "run", "-d", "web-server", "--web-port=8080", "--web-hostname=0.0.0.0"]

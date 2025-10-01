# ===================================================================
# Dockerfile Otimizado e Seguro (Multi-Stage Build)
# ===================================================================

# --- Estágio 1: Build da Aplicação ---
# Usamos uma imagem oficial do Maven com Java 17 para compilar o projeto.
FROM maven:3.9-eclipse-temurin-17 AS build

# Define o diretório de trabalho dentro do contêiner de build.
WORKDIR /app

# Copia apenas o pom.xml para aproveitar o cache de camadas do Docker.
# As dependências só serão baixadas de novo se o pom.xml mudar.
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copia o resto do código-fonte.
COPY src ./src

# Compila a aplicação e gera o .jar executável.
# O -B (batch mode) evita logs interativos.
RUN mvn clean package -DskipTests -B


# --- Estágio 2: Imagem Final de Execução ---
# Usamos uma imagem JRE (Java Runtime Environment) super leve baseada em Ubuntu.
# É mais segura e menor que uma imagem JDK completa.
FROM eclipse-temurin:17-jre-jammy

# Define o diretório de trabalho na imagem final.
WORKDIR /app

# Cria um usuário e grupo não-root chamado "appuser" para rodar a aplicação.
# Isso cumpre o requisito de segurança de não rodar como root.
RUN groupadd -r appgroup && useradd -r -g appgroup appuser

# Copia o arquivo .jar gerado no estágio de build para a imagem final.
COPY --from=build /app/target/*.jar app.jar

# Dá a posse dos arquivos para o nosso usuário não-root.
RUN chown appuser:appgroup app.jar

# Muda para o usuário não-root.
USER appuser

# Expõe a porta 8080, que é a porta padrão do Spring Boot.
EXPOSE 8080

# Comando final para iniciar a aplicação quando o contêiner rodar.
ENTRYPOINT ["java", "-jar", "app.jar"]
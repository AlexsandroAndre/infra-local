# Projeto `infra-local`

Este repositório contém a configuração de infraestrutura local para o desenvolvimento dos microserviços do Projeto Impiricus. Ele utiliza Docker Compose para orquestrar os serviços essenciais de banco de dados e monitoramento.

## Serviços Incluídos

- **PostgreSQL**: Banco de dados relacional para persistência dos dados dos microserviços.
- **Prometheus**: Sistema de monitoramento e alerta para coletar métricas dos microserviços.
- **Grafana**: Plataforma de visualização e análise de métricas, utilizando dados do Prometheus.

## Estrutura do Repositório

```text
infra-local/
  docker-compose.yml        # Define os serviços Docker
  .gitignore                # Ignora arquivos e pastas gerados
  README.md                 # Este arquivo
  postgres/
    init.sql                # Script de inicialização do PostgreSQL (criação de tipos/tabelas)
    data/                   # Volume para dados do PostgreSQL (ignorado pelo Git)
  prometheus/
    prometheus.yml          # Configuração do Prometheus para coletar métricas
  grafana/
    dashboards/             # Pasta para dashboards do Grafana (arquivos JSON)
      api-overview.json
      microservice-overview.json
    grafana-storage/        # Volume para dados do Grafana (ignorado pelo Git)
```

## Pré-requisitos

Para utilizar este ambiente, você precisa ter o Docker e o Docker Compose instalados em sua máquina.

- Docker Desktop (Windows e macOS)
- Docker Engine e Docker Compose (Linux)

## Como Iniciar

1. **Clone este repositório:**

   ```bash
   git clone <URL_DO_SEU_REPOSITORIO>
   cd infra-local
   ```

2. **Inicie os serviços Docker:**

   ```bash
   docker-compose up -d
   ```

   Este comando irá baixar as imagens necessárias (se ainda não as tiver), criar e iniciar os contêineres em segundo plano.

3. **Verifique o status dos serviços:**

   ```bash
   docker-compose ps
   ```

   Todos os serviços devem estar com o status `Up`.

## Acessando os Serviços

Após iniciar os contêineres, você pode acessar os serviços nos seguintes endereços:

### PostgreSQL

- Host: `localhost`
- Porta: `5432`
- Usuário: `impiricus`
- Senha: `impiricus`
- Banco de Dados: `projeto_impiricus`

### Prometheus

- Interface Web: http://localhost:9090

### Grafana

- Interface Web: http://localhost:3000
- Usuário padrão: `admin`
- Senha padrão: `admin`

## Configuração do Grafana

1. Acesse o Grafana em http://localhost:3000 e faça login com `admin` / `admin`.

2. Adicione o Prometheus como Data Source:
    - No menu lateral, vá em `Connections` → `Data sources` → `Add new data source`.
    - Selecione `Prometheus`.
    - No campo `URL`, insira:

      ```text
      http://prometheus:9090
      ```

      (este é o nome do serviço Prometheus dentro da rede Docker).

    - Clique em `Save & test`.

3. Importe os Dashboards:
    - No menu lateral, vá em `Dashboards` → `Import`.
    - Clique em `Upload JSON file` e selecione os arquivos `.json` localizados na pasta `grafana/dashboards/` deste projeto (`api-overview.json`, `microservice-overview.json`).
    - Certifique-se de selecionar o `Prometheus` como o Data Source para cada dashboard importado.

## Parando os Serviços

Para parar e remover os contêineres, volumes e redes criados pelo Docker Compose:

```bash
docker-compose down -v
```

O parâmetro `-v` remove os volumes de dados, o que é útil para começar com um estado limpo, mas pode apagar dados importantes se você já tiver algo no PostgreSQL.

Para apenas parar sem remover os dados, use:

```bash
docker-compose down
```

## Monitoramento dos Microserviços

Para que o Prometheus possa coletar métricas dos seus microserviços (Core Data Service e Projeto API), certifique-se de que eles estão configurados para expor métricas no endpoint:

```text
/actuator/prometheus
```

e que estão rodando nas portas esperadas (por exemplo, `8080` e `8081`).

O arquivo `prometheus/prometheus.yml` já está configurado para buscar métricas em:

- `host.docker.internal:8080` (microserviço Core Data)
- `host.docker.internal:8081` (Projeto API coletor)

Ajuste as portas se você utilizar configurações diferentes nos seus serviços Spring Boot.

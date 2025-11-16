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
# AgroSense Mesh Mobile (Marco 2 — AP2B)
> Aplicativo Móvel Offline-First em Flutter para Telemetria Agrícola e Irrigação Automatizada de Precisão.

[![Flutter](https://img.shields.io/badge/Flutter-3.22+-02569B.svg?style=flat-square&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.3+-0175C2.svg?style=flat-square&logo=dart&logoColor=white)](https://dart.dev)
[![Architecture](https://img.shields.io/badge/Architecture-Offline--First-10B981.svg?style=flat-square)]()
[![Persistence](https://img.shields.io/badge/SQLite-sqflite-003B57.svg?style=flat-square&logo=sqlite&logoColor=white)](https://pub.dev/packages/sqflite)

---

## 🌾 1. Contexto e Tema do Projeto
O **AgroSense Mesh Mobile** é a evolução móvel da plataforma distribuída de telemetria agrícola (**Tema 01 — Mobilidade Urbana, Sensores e Telemetria**).

O sistema resolve o desafio crítico de conectividade intermitente em ambientes rurais através de uma **Arquitetura Offline-First**:
1. **Fonte Única da Verdade (Single Source of Truth):** Todas as leituras de umidade, temperatura e nível de bateria são gravadas primeiro no banco de dados relacional local **SQLite (`sqflite`)**.
2. **Escrita Resiliente com Fallback:** As operações recebem imediatamente a marcação `sincronizado = false` (ou `0`). Em caso de falha de socket, timeout ou modo avião, o aplicativo continua 100% operacional sem perda de dados.
3. **Regra de Negócio de Campo:** Ao registrar uma leitura onde $\text{Umidade do Solo} < 40.0\%$, o sistema aciona e persiste automaticamente um registro na tabela relacionada `eventos_irrigacao`, registrando o volume de água em litros e a válvula acionada.
4. **Sincronização em Lote:** Quando a conectividade 4G/Wi-Fi é restabelecida, a rotina assíncrona envia os lotes pendentes para a API REST externa e atualiza o estado local para `sincronizado = true`.

---

## 🏛️ 2. Diagrama da Arquitetura Offline-First

```
+-----------------------------------------------------------------------+
|                       CAMADA DE APRESENTAÇÃO (UI)                     |
|           10 Rotas Integradas em Material Design 3 (Flutter)          |
|      (Dashboard, Leituras, Formulários Validados, Zonas A-E, Sync)     |
+-----------------------------------+-----------------------------------+
                                    |
                    Leitura/Escrita Assíncrona (Future)
                                    v
+-----------------------------------------------------------------------+
|                         CAMADA DE REPOSITÓRIO                         |
|             TelemetriaRepository (Orquestração e Fallback)            |
+-----------------+-----------------------------------+-----------------+
                  |                                   |
    1. Prioridade Local (CRUD Sempre Ativo)   2. Sincronização HTTP (Quando Online)
                  v                                   v
+-----------------------------------+   +-------------------------------+
|     FONTE DE DADOS LOCAL (DAO)    |   |     FONTE DE DADOS REMOTA     |
|      SQLite (sqflite) Local       |   |       Cliente HTTP REST       |
|   Tabelas: telemetrias, irrigacao |   |  Timeout 5s & Resiliência     |
+-----------------------------------+   +-------------------------------+
```

---

## 📱 3. As 10 Rotas Integradas da Aplicação

| Rota | Tela / Widget | Finalidade e Componentes |
| :--- | :--- | :--- |
| `/` | `SplashScreen` | Inicialização e verificação de integridade do SQLite local. |
| `/dashboard` | `DashboardScreen` | Métricas de solo, umidade média, cards de atalho e status de sync. |
| `/leituras` | `LeiturasListScreen` | `ListView.builder` dinâmico com filtro por zona e exclusão por gesto `Dismissible`. |
| `/leituras/novo` | `NovaLeituraScreen` | Formulário estruturado com `Form`, `GlobalKey<FormState>`, `TextFormField` e validações. |
| `/leituras/detalhes` | `DetalheLeituraScreen` | Passagem segura de argumentos via rotas, gauges de solo e dados brutos. |
| `/irrigacao` | `IrrigacaoHistoricoScreen` | Histórico consolidado de consumo d'água e acionamentos de válvulas. |
| `/irrigacao/novo` | `NovoComandoIrrigacaoScreen` | Formulário para disparo forçado de válvula com validação de volume em litros. |
| `/zonas` | `MapaZonasScreen` | Visão geral das 5 Zonas de Plantio (Zonas A, B, C, D e E). |
| `/zonas/detalhes` | `DetalheZonaScreen` | Detalhamento estatístico de uma zona e seus sensores ativos. |
| `/sincronizacao` | `DiagnosticoSyncScreen` | Painel de controle de rede, contagem de pendências e botão de envio em lote. |

---

## 🧪 4. Suíte de Testes Automatizados (25 Casos)

A suíte de testes cobre integralmente os requisitos da AP2B:
- **Testes de Unidade (20 testes):**
  - `test/unit/telemetria_model_test.dart` (7 testes): serialização `toMap`/`fromMap`, tratamento booleano 0/1, validação de limites de bateria/umidade e regra de irrigação.
  - `test/unit/irrigacao_model_test.dart` (5 testes): integridade relacional, cálculo de volume hídrico e cópia imutável com `copyWith`.
  - `test/unit/telemetria_repository_test.dart` (8 testes): simulação de fallback offline com `MockClient`, erro 500, persistência imediata com `sincronizado: false` e acionamento automático de irrigação.
- **Testes de Widgets (5 testes):**
  - `test/widgets/telemetria_widgets_test.dart` (5 testes): renderização de badges, gauges de umidade, validação de formulários obrigatórios e drawer de navegação.

---

## 🚀 5. Instruções de Execução

```bash
# 1. Navegar até o diretório do aplicativo móvel
cd mobile

# 2. Obter as dependências
flutter pub get

# 3. Executar a suíte completa de 25 testes automatizados
flutter test

# 4. Executar o aplicativo no emulador ou dispositivo físico
flutter run
```

---

## 👥 6. Informações da Equipe

- **Caio Lennon**
- **Livia Louzada**
- **Julia Vionette**

**Instituição:** Faculdade Multivix  
**Curso:** Bacharelado em Sistemas de Informação  
**Disciplina:** Computação Móvel (2026/2) — Professor Edgard da Cunha Pontes  

---

## 🤖 7. Declaração Institucional Obrigatória de Uso de IA

* **Ferramentas Utilizadas:** Google Antigravity IDE e Google Gemini (DeepMind).
* **Finalidade do Uso:** Apoio consultivo na estruturação dos contratos de repositório com inversão de dependência, aceleração da escrita de testes automatizados com `MockClient` do pacote `http/testing.dart`, e formatação visual dos componentes em Material Design 3.
* **Autoria e Domínio Cognitivo:** A concepção da arquitetura Offline-First, a modelagem das entidades relacionais (`RegistroTelemetria` e `EventoIrrigacao`), as regras de negócio de irrigação automatizada e o domínio completo do código-fonte para a defesa técnica oral são de responsabilidade integral dos integrantes da equipe.

---

## 📚 8. Referências Bibliográficas

* TEIXEIRA, Giovany Frossard et al. **Fundamentos de Flutter e Dart para desenvolvimento de apps móveis**. Vitória: Edifes, 2024.
* FLUTTER DEV. **Building Applications with Flutter**. Google, 2026. Disponível em: <https://docs.flutter.dev>.
* DART DEV. **Dart Language Guide and Tour**. Google, 2026. Disponível em: <https://dart.dev/docs>.


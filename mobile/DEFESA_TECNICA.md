# 🎓 Guia Completo para Defesa Técnica Presencial — AgroSense Mesh Mobile (AP2B)

> **Instituição:** Faculdade Multivix  
> **Curso:** Bacharelado em Sistemas de Informação  
> **Disciplina:** Computação Móvel (2026/2) — Professor Edgard da Cunha Pontes  
> **Tema:** Tema 01 — Mobilidade Urbana, Sensores e Telemetria Agrícola (*AgroSense Mesh*)  
> **Equipe:** Caio Lennon, Livia Louzada, Julia Vionette  
> **Data da Defesa:** Semana 15 (10/11/2026 a 12/11/2026)  
> **Pontuação da Etapa 2:** 1,50 Ponto (Total da AP2B: 3,00 Pontos)  

---

## 🎯 Estratégia de Apresentação: Modalidade A (Recomendada)

Conforme a **Página 7 do Edital**, a equipe pode escolher entre duas modalidades:
- **Modalidade A (Com Apresentação Técnica — Altamente Recomendada):**
  - Demonstração prática do app funcionando **online e offline** no emulador + execução limpa do comando `flutter test` em até 6 minutos: **Garante 0,50 ponto base imediato**.
  - Responder a **2 perguntas técnicas** sorteadas/individuais (0,50 ponto cada = 1,00 ponto).
  - *Total: 0,50 + 1,00 = **1,50 ponto máximo**.*
- **Modalidade B (Direto para Arguição Técnica):**
  - Sabatina direta respondendo a 4 questões técnicas com alteração de código ao vivo (0,50 pt por questão).

---

## 🎤 Roteiro de Demonstração Prática (5 a 6 Minutos)

### Minuto 0:00 a 1:30 — Abertura e Arquitetura Offline-First (Integrante 1)
> *"Boa noite, professor Edgard. Nosso projeto é o **AgroSense Mesh Mobile**, evolução do Tema 01 de Telemetria e Sensores da AP1B. 
> No agronegócio de precisão, a conectividade rural é intermitente. Por isso, adotamos estritamente a arquitetura **Offline-First**, onde o banco de dados relacional local **SQLite (`sqflite`)** atua como nossa **Fonte Única da Verdade (Single Source of Truth)**. 
> Nossos widgets não conhecem SQL nem chamadas HTTP: a UI se comunica apenas com o `TelemetriaRepository`, que orquestra a gravação imediata local e o envio assíncrono para a nuvem."*

### Minuto 1:30 a 3:30 — Demonstração Prática: Modo Online vs. Modo Avião (Integrante 2)
1. **Com o emulador com rede ligada:**
   - Abra a tela **"Nova Leitura"** (`/leituras/novo`).
   - Cadastre uma leitura normal: Sensor `SENSOR-A1`, Zona A, Umidade `48.0%`, Temperatura `26°C`.
   - Clique em salvar. Mostre a notificação verde e o badge **`✓ Sincronizado`**.
2. **Simulando Queda de Rede (Modo Avião):**
   - Ative o **Modo Avião** no emulador Android (ou desconecte o Wi-Fi).
   - Cadastre uma leitura crítica: Sensor `SENSOR-B2`, Zona B, Umidade `32.5%` ($< 40\%$).
   - Clique em salvar: o app grava instantaneamente no SQLite sem travar e exibe o badge laranja **`⏳ Pendente`**.
   - Abra a tela **"Histórico de Irrigação"** (`/irrigacao`): mostre que a regra de negócio do AgroSense disparou automaticamente o acionamento da válvula da Zona B para salvar a lavoura, mesmo offline!
3. **Ressincronização com a Nuvem:**
   - Desative o Modo Avião.
   - Abra a tela **"Diagnóstico & Sincronização"** (`/sincronizacao`) e clique em **"Sincronizar Cloud Agora"**.
   - Mostre que o lote pendente é transmitido via HTTP REST e o status no banco vira `✓ Sincronizado`.

### Minuto 3:30 a 5:00 — Demonstração das Telas e Gestos (Integrante 3)
- Apresente o menu lateral (`AppDrawer`) demonstrando a transição fluida entre as **10 rotas integradas**.
- Mostre a tela de listagem de leituras (`/leituras`) executando a remoção de um registro por gesto com **`Dismissible`** (arrastando para a esquerda com confirmação).
- Demonstre a validação do formulário tentando salvar com campos vazios (provando o funcionamento dos validadores de `TextFormField`).

### Minuto 5:00 a 6:00 — Execução da Suíte de Testes no Terminal (Todos)
No terminal da IDE, execute:
```bash
cd mobile
flutter test
```
> *"Professor, nossa suíte possui **25 testes automatizados** — 20 testes de unidade validando serialização, limites de bateria e fallback offline com `MockClient`, e 5 testes de widgets comprovando a renderização de listas e validações de formulário — todos passando com 100% de sucesso."*

---

## 📚 Banco de Questões Difíceis para a Sabatina do Professor

Abaixo estão as perguntas conceituais e práticas mais prováveis de serem feitas pelo professor Edgard da Cunha Pontes, acompanhadas das respostas ideais fundamentadas no código do AgroSense Mesh Mobile:

---

### ❓ Pergunta 1: *"Qual a diferença entre a Árvore de Widgets (Widget Tree), a Árvore de Elementos (Element Tree) e a Árvore de Renderização (Render Tree) no Flutter?"*
**Resposta Ideal:**
> *"No Flutter existem três árvores fundamentais que trabalham de forma coordenada:
> 1. **Widget Tree:** É uma árvore de configurações imutáveis e declarativas, extremamente leve. Descreve como a UI deveria parecer. É recriada constantemente a cada chamada de `build()`.
> 2. **Element Tree:** É a árvore que gerencia o ciclo de vida e a identidade dos nós na tela. Ela atua como ponte inteligente entre o Widget e o RenderObject. Quando um Widget muda, o `Element` correspondente verifica se o tipo e a `Key` são iguais (`Widget.canUpdate`); se forem, ele apenas atualiza sua referência sem recriar objetos pesados na memória.
> 3. **Render Tree (RenderObject Tree):** É a árvore mutável responsável pelo layout geométrico (tamanho, posição, restrições *box constraints*) e pela pintura real dos pixels na tela via GPU (Skia ou Impeller). Ela é preservada ao máximo para garantir os 60/120 FPS do Flutter."*

---

### ❓ Pergunta 2: *"Por que é obrigatório liberar os `TextEditingController` no método `dispose()` de um `StatefulWidget`? O que aconteceria se não fizéssemos isso?"*
**Resposta Ideal:**
> *"Em linguagens com Garbage Collection como o Dart, referências circulares ou ouvintes nativos registrados no engine não são coletados automaticamente se houver listeners pendentes. 
> O `TextEditingController` é um `ChangeNotifier` que cria vínculos no nível do framework do Flutter e da plataforma nativa (teclado virtual). 
> Se não chamarmos `controller.dispose()` dentro do método `dispose()` da State ([`nova_leitura_screen.dart:40-47`](file:///c:/Users/Caio%20Lennon/Documents/Programa--o-Distribuida/mobile/lib/screens/nova_leitura_screen.dart#L40-L47)), toda vez que o usuário entrar e sair da tela de formulário, uma nova instância permanecerá retida na memória, gerando um **Memory Leak (vazamento de memória)** progressivo que degrada o desempenho do dispositivo móvel."*

---

### ❓ Pergunta 3: *"Como o Dart executa código assíncrono com `Future` e `async/await` se ele é uma linguagem single-threaded (executa em apenas uma thread)?"*
**Resposta Ideal:**
> *"O Dart executa dentro de um **Isolate**, que possui sua própria memória e um **Event Loop**. 
> O Event Loop gerencia duas filas prioritárias:
> 1. **Microtask Queue:** Executada primeiro, para tarefas internas ultrarrápidas do runtime.
> 2. **Event Queue:** Onde entram eventos externos de I/O, timers, toques na tela e respostas HTTP de rede.
> Quando chamamos `await _remoteDatasource.enviarTelemetria()`, a thread do Dart **não é bloqueada**. O Dart suspende temporariamente a execução daquela função assíncrona, registra um callback na Event Queue e continua livre para redesenhar a tela a 60 FPS. Quando o sistema operacional notifica a chegada dos bytes da rede via socket, o callback é enfileirado na Event Queue e o código retoma a partir do ponto do `await`."*

---

### ❓ Pergunta 4: *"Como o padrão Inversão de Dependência (SOLID) no `TelemetriaRepository` viabilizou a criação de testes de unidade sem emulador?"*
**Resposta Ideal:**
> *"Em vez de instanciar `DatabaseHelper()` ou `http.Client()` internamente com `new`, a classe [`TelemetriaRepository`](file:///c:/Users/Caio%20Lennon/Documents/Programa--o-Distribuida/mobile/lib/repositories/telemetria_repository.dart#L30-L38) depende de contratos abstratos: `TelemetriaLocalDatasource` e `TelemetriaRemoteDatasource`.
> Isso nos permitiu criar a classe [`FakeLocalDatasource`](file:///c:/Users/Caio%20Lennon/Documents/Programa--o-Distribuida/mobile/test/unit/telemetria_repository_test.dart#L12-L55) em memória (usando `Map<String, RegistroTelemetria>`) e injetar um [`MockClient`](file:///c:/Users/Caio%20Lennon/Documents/Programa--o-Distribuida/mobile/test/unit/telemetria_repository_test.dart#L112-L113) do pacote `package:http/testing.dart`. 
> Dessa forma, nossa suíte em `test/unit/telemetria_repository_test.dart` roda em frações de milissegundo no console sem precisar de emulador Android, sem compilar SQLite C-FFI e sem depender de conexão real com a internet."*

---

### ❓ Pergunta 5: *"O que acontece no SQLite se dois registros com o mesmo `id` forem inseridos? Como o código trata isso?"*
**Resposta Ideal:**
> *"No arquivo [`telemetria_local_datasource.dart`](file:///c:/Users/Caio%20Lennon/Documents/Programa--o-Distribuida/mobile/lib/datasources/telemetria_local_datasource.dart#L40-L45), utilizamos a estratégia de conflito `ConflictAlgorithm.replace` no comando `db.insert`. 
> Se um registro com o mesmo `id` já existir na chave primária da tabela `telemetrias`, o SQLite executa um `UPSERT` (atualiza as colunas em vez de estourar uma exceção de violação de unicidade `DatabaseException`). 
> Isso é fundamental no Offline-First, pois quando a sincronização com a nuvem confirma o envio e atualizamos `sincronizado: true`, a mesma linha é atualizada de forma segura."*

---

## 💻 Desafios de Live Coding (Alteração de Código ao Vivo na Frente do Professor)

O professor pode pedir uma pequena alteração no código para testar se vocês realmente dominam a implementação. Abaixo estão os cenários mais comuns e como resolver em segundos:

### Desafio 1: *"Mude a regra de acionamento de irrigação para ligar a válvula se a umidade for menor que 35% em vez de 40%."*
- **Onde alterar:**
  1. No modelo [`registro_telemetria.dart`](file:///c:/Users/Caio%20Lennon/Documents/Programa--o-Distribuida/mobile/lib/models/registro_telemetria.dart#L28):
     ```dart
     // Mude de:
     bool get precisaIrrigacao => umidadeSolo < 40.0;
     // Para:
     bool get precisaIrrigacao => umidadeSolo < 35.0;
     ```
  2. No repositório [`telemetria_repository.dart`](file:///c:/Users/Caio%20Lennon/Documents/Programa--o-Distribuida/mobile/lib/repositories/telemetria_repository.dart#L64):
     ```dart
     motivo: 'Umidade do solo em ${pendente.umidadeSolo.toStringAsFixed(1)}% (< 35.0%)',
     ```

### Desafio 2: *"Adicione um novo campo booleano `sensorCalibrado` no modelo de telemetria."*
- **Onde alterar:**
  1. No arquivo [`registro_telemetria.dart`](file:///c:/Users/Caio%20Lennon/Documents/Programa--o-Distribuida/mobile/lib/models/registro_telemetria.dart):
     ```dart
     final bool sensorCalibrado;
     
     // No construtor:
     this.sensorCalibrado = true,
     
     // No toMap():
     'sensor_calibrado': sensorCalibrado ? 1 : 0,
     
     // No fromMap():
     sensorCalibrado: map['sensor_calibrado'] == 1 || map['sensor_calibrado'] == true,
     ```

### Desafio 3: *"Adicione um novo caso de teste validando que uma umidade de 38% não aciona a irrigação com o novo limiar de 35%."*
- **Onde alterar:**
  1. No arquivo [`telemetria_model_test.dart`](file:///c:/Users/Caio%20Lennon/Documents/Programa--o-Distribuida/mobile/test/unit/telemetria_model_test.dart):
     ```dart
     test('Deve respeitar o novo limiar de 35%', () {
       final t = RegistroTelemetria(
         id: 'TEL-X',
         sensorId: 'SENSOR-X',
         zona: 'Zona A',
         umidadeSolo: 38.0,
         temperatura: 25.0,
         nivelBateria: 90,
         timestamp: DateTime.now(),
       );
       expect(t.precisaIrrigacao, isFalse);
     });
     ```


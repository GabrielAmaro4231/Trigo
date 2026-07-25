# Trigo

Trigo é um aplicativo mobile desenvolvido em Flutter para auxiliar no controle de gastos de forma simples, rápida e offline. A proposta do projeto é transformar um orçamento definido pelo usuário em uma referência diária de uso, ajudando a visualizar quanto ainda pode ser gasto ao longo do período escolhido.

O projeto é inspirado no aplicativo Buckwheat, desenvolvido originalmente para Android nativo. Como parte de um estudo acadêmico sobre desenvolvimento híbrido, o objetivo deste trabalho é portar as principais funcionalidades desse aplicativo existente para uma implementação em Flutter, avaliando como uma mesma ideia de produto pode ser reorganizada em uma base multiplataforma.

O nome Trigo foi escolhido como uma homenagem ao aplicativo que inspirou o projeto, mantendo a relação conceitual com Buckwheat sem utilizar exatamente o mesmo nome da aplicação original.

## Ideia do aplicativo

A ideia central do Trigo é reduzir a complexidade comum em aplicativos financeiros. Em vez de exigir cadastros extensos, sincronização online ou várias etapas para registrar uma despesa, o aplicativo trabalha com um fluxo direto:

1. O usuário informa o orçamento disponível.
2. Define até quando esse orçamento deve durar.
3. O aplicativo distribui esse valor entre os dias do período.
4. O usuário registra despesas por meio de uma tela semelhante a uma calculadora.
5. O saldo diário é atualizado imediatamente.

Quando sobra dinheiro em um dia, o valor restante é carregado para o dia seguinte. Dessa forma, o orçamento diário acompanha melhor o comportamento real do usuário, sem perder a referência do planejamento inicial.

## Estrutura do projeto

```text
lib/
  main.dart
  src/
    app.dart
    features/
      setup/
      transactions/
    models/
    theme/
    utils/
    widgets/
test/
```

Principais áreas:

- `features/setup`: tela de configuração do orçamento.
- `features/transactions`: tela de lançamento, lista de transações e gerenciamento de categorias.
- `models`: estruturas de dados principais do aplicativo.
- `utils`: funções de datas, dinheiro e cálculo de orçamento diário.
- `widgets`: componentes visuais reutilizáveis.
- `theme`: definição do tema visual da aplicação.

## Tecnologias utilizadas

- Flutter
- Dart
- Material Design
- Testes com `flutter_test`

## Como executar

Antes de executar, é necessário ter o Flutter configurado na máquina.

```sh
flutter pub get
flutter run
```

## Verificações

Para validar o projeto localmente:

```sh
flutter analyze
flutter test
```

Também é possível gerar um APK debug com:

```sh
flutter build apk --debug
```

# Flow: Title

> **Resumo:** Mostra a tela de titulo do jogo e envia o usuario para a partida quando ele toca em Launch.

## Visão Geral

O fluxo de Title comeca quando a tela de loading conclui o preload e navega para `TitlePage.route()`. A tela exibe um `AppBar` com o nome do jogo e um botao centralizado.

Os textos sao obtidos via `context.l10n`, usando as chaves geradas a partir de `app_en.arb`. Ao tocar no botao, `TitleView` faz `Navigator.pushReplacement` para `GamePage.route()`, removendo a tela de titulo da pilha.

## Passo a Passo

1. **Origem** — `lib/loading/view/loading_page.dart` → `onPreloadComplete`
   Apos o preload, chama `navigator.pushReplacement(TitlePage.route())`.
2. **Rota** — `lib/title/view/title_page.dart` → `TitlePage.route`
   Cria uma `MaterialPageRoute<void>` para `TitlePage`.
3. **Tela** — `lib/title/view/title_page.dart` → `TitlePage.build`
   Renderiza `Scaffold`, `AppBar` com `l10n.titleAppBarTitle` e `TitleView`.
4. **Acao do usuario** — `lib/title/view/title_page.dart` → `TitleView.build`
   Exibe um `ElevatedButton` de 250x64 com `l10n.titleButtonStart`.
5. **Navegacao** — `lib/title/view/title_page.dart` → `onPressed`
   Ao tocar no botao, faz `Navigator.of(context).pushReplacement(GamePage.route())`.
6. **Destino** — `lib/game/view/game_page.dart` → `GamePage.route`
   Cria a rota da tela de jogo.

## Arquivos Envolvidos

| Camada | Arquivo | Responsabilidade |
|--------|---------|------------------|
| Apresentacao | `lib/title/view/title_page.dart` | Define tela, botao Launch e navegacao para o jogo. |
| Navegacao | `lib/loading/view/loading_page.dart` | Entra no fluxo de Title apos completar preload. |
| Navegacao | `lib/game/view/game_page.dart` | Rota de destino quando o usuario inicia o jogo. |
| L10n | `lib/l10n/arb/app_en.arb` | Define `titleAppBarTitle` e `titleButtonStart`. |
| Barrel | `lib/title/title.dart` | Exporta a view da feature Title. |
| Testes | `test/title/view/title_page_test.dart` | Cobre renderizacao e navegacao da tela de titulo. |

## Regras de Negócio Relevantes

- **Launch substitui a rota atual** — `lib/title/view/title_page.dart`: o jogo e aberto com `pushReplacement`, entao a tela de titulo nao permanece abaixo de `GamePage`.
- **Textos localizados** — `lib/title/view/title_page.dart`: AppBar e botao dependem de `context.l10n`.

## Dependências Externas

- Flutter Material para `Scaffold`, `AppBar`, `ElevatedButton`, `Navigator` e `MaterialPageRoute`.

## Observações

- Nao ha estado proprio na feature Title.
- Nao ha menu, configuracao ou selecao de fase antes de iniciar o jogo.

# Flow: Title

> **Resumo:** Mostra a home tematica do jogo, permite trocar idioma, permite mutar o audio e envia o usuario para a partida quando ele toca em Launch/Decolar.

## Visão Geral

O fluxo de Title comeca quando a tela de loading conclui o preload e navega para `TitlePage.route()`. A tela renderiza uma home fullscreen com fundo espacial, nave, meteoros, briefing de missao e botao principal de partida.

Os textos sao obtidos via `context.l10n`, usando as chaves geradas a partir dos ARBs. O seletor de idioma no topo aciona `AppLocaleCubit.setLocale`, que atualiza o `Locale` do `MaterialApp`; antes da selecao manual, o app usa o locale resolvido pelo sistema. A top bar tambem exibe o botao de volume ligado ao `AudioCubit` global, permitindo alternar entre audio ligado e mutado antes de iniciar a partida. Ao tocar no botao principal, `TitleView` faz `Navigator.pushReplacement` para `GamePage.route()`, removendo a tela de titulo da pilha.

## Passo a Passo

1. **Origem** — `lib/loading/view/loading_page.dart` → `onPreloadComplete`
   Apos o preload, chama `navigator.pushReplacement(TitlePage.route())`.
2. **Rota** — `lib/title/view/title_page.dart` → `TitlePage.route`
   Cria uma `MaterialPageRoute<void>` para `TitlePage`.
3. **Tela** — `lib/title/view/title_page.dart` → `TitlePage.build`
   Renderiza `Scaffold` fullscreen com `SafeArea` e `TitleView`.
4. **Home** — `lib/title/view/title_page.dart` → `TitleView.build`
   Le `AppLocaleCubit` via `context.select`, monta fundo espacial (`TitleBackdrop`), top bar (`TitleTopBar`) e conteudo principal (`TitleMainContent`).
5. **Layout** — `lib/title/content/title_main_content.dart` → `TitleMainContent.build`
   Usa `MediaQuery.sizeOf` para passar `isWide` ao `TitleHero` (breakpoint 760px) e renderiza `Column` simples com `TitleHero`, espaco e `TitleStartButton`.
6. **Idioma** — `lib/title/content/title_top_bar.dart` → `TitleTopBar`
   Mostra `PopupMenuButton<Locale>` com opcoes EN/PT usando `TitleLanguageMenuItem` e chama `AppLocaleCubit.setLocale` ao selecionar uma opcao.
7. **Mute** — `lib/title/content/title_top_bar.dart` → `BlocBuilder<AudioCubit, AudioState>`
   Mostra `Icons.volume_up` ou `Icons.volume_off` conforme `AudioState.volume` e chama `AudioCubit.toggleVolume` ao tocar no botao.
8. **Acao do usuario** — `lib/title/content/title_start_button.dart` → `TitleStartButton`
   Exibe um `ElevatedButton.icon` com `l10n.titleButtonStart`.
9. **Navegacao** — `lib/title/content/title_start_button.dart` → `onPressed`
   Ao tocar no botao, faz `Navigator.of(context).pushReplacement(GamePage.route())`.
10. **Destino** — `lib/game/view/game_page.dart` → `GamePage.route`
   Cria a rota da tela de jogo.

## Arquivos Envolvidos

| Camada | Arquivo | Responsabilidade |
|--------|---------|------------------|
| Apresentacao — View | `lib/title/view/title_page.dart` | Define `TitlePage` (routing shell com `SafeArea`) e `TitleView` (orquestra estado e estrutura principal). |
| Apresentacao — Content | `lib/title/content/title_backdrop.dart` | Fundo espacial com imagem, gradientes e glow radial. |
| Apresentacao — Content | `lib/title/content/title_top_bar.dart` | Top bar com seletor de idioma e botao de mute ligado ao `AudioCubit`. |
| Apresentacao — Content | `lib/title/content/title_hero.dart` | Nave, meteoros, headline e subtitulo do hero. |
| Apresentacao — Content | `lib/title/content/title_main_content.dart` | `LayoutBuilder` responsivo que orquestra hero, console e botao. |
| Apresentacao — Content | `lib/title/content/title_start_button.dart` | Botao Launch/Decolar e navegacao para `GamePage`. |
| Apresentacao — Content | `lib/title/content/title_language_menu_item.dart` | Item do menu de idioma com icone de selecao. |
| Estado / Cubit | `lib/app/cubit/app_locale_cubit.dart` | Mantem o locale selecionado pelo usuario; persiste em storage e restaura no proximo lancamento. |
| Estado / Cubit | `lib/game/cubit/audio/audio_cubit.dart` | Mantem o volume global, aplica volume nos players e persiste a escolha. |
| Estado | `lib/game/cubit/audio/audio_state.dart` | Guarda o volume atual usado para escolher icone e tooltip do botao de mute. |
| Servico | `lib/common/services/storage_service.dart` | Interface de storage usada por `AppLocaleCubit` e `AudioCubit` para ler e salvar preferencias. |
| Navegacao | `lib/loading/view/loading_page.dart` | Entra no fluxo de Title apos completar preload. |
| Navegacao | `lib/game/view/game_page.dart` | Rota de destino quando o usuario inicia o jogo. |
| L10n | `lib/l10n/arb/app_en.arb` | Define strings em ingles da home. |
| L10n | `lib/l10n/arb/app_pt.arb` | Define strings em portugues da home. |
| Barrel | `lib/title/title.dart` | Exporta a view da feature Title (apenas `title_page.dart`; arquivos em `content/` sao internos). |
| Testes | `test/title/view/title_page_test.dart` | Cobre renderizacao, troca de idioma, mute e navegacao da tela de titulo. |

## Regras de Negócio Relevantes

- **Launch substitui a rota atual** — `lib/title/content/title_start_button.dart`: o jogo e aberto com `pushReplacement`, entao a tela de titulo nao permanece abaixo de `GamePage`.
- **Idioma persistido em storage** — `lib/app/cubit/app_locale_cubit.dart`: ao inicializar, `init()` le a chave `app_locale` do `StorageService` e emite o locale salvo; `setLocale` salva o `languageCode` antes de emitir; sem selecao manual o app usa a resolucao padrao do sistema.
- **Mute compartilhado com gameplay** — `lib/title/content/title_top_bar.dart` e `lib/game/cubit/audio/audio_cubit.dart`: o botao da Title altera o mesmo `AudioCubit` global usado pela Game, entao a escolha vale ao entrar na partida.
- **Textos localizados** — todos os textos visiveis dependem de `context.l10n`; nenhuma string visivel e hardcoded.
- **Content nao exportado** — os arquivos em `lib/title/content/` sao auxiliares internos da feature e nao sao expostos pelo barrel `lib/title/title.dart`.

## Dependências Externas

- Flutter Material para `Scaffold`, `ElevatedButton`, `PopupMenuButton`, `Navigator` e `MaterialPageRoute`.
- `flutter_bloc` para ler e atualizar `AppLocaleCubit` e `AudioCubit`.
- `dart:ui` — não há mais dependência direta na feature Title.

## Observações

- Nao ha estado proprio dentro da feature Title; os estados consumidos sao os Cubits globais `AppLocaleCubit` e `AudioCubit`.
- O idioma escolhido e persistido via `StorageService` e restaurado automaticamente no proximo lancamento.
- O breakpoint de 760px (definido em `TitleMainContent`) apenas controla o `isWide` passado ao `TitleHero` (tamanho de fonte e alinhamento de texto); nao ha mais bifurcacao de layout para o console.

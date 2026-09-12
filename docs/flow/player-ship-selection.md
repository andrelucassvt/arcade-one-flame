---
generated_at: 2026-09-12
source_commit: 698131b
source_state: clean
verified_at: 2026-09-12
status: current
related_plans:
  - docs/plan/player-ship-unlocks.md
  - docs/plan/space-background-by-km.md
---

# Flow: Player Ship Selection

> **Resumo:** Libera skins pelos recordes de distância, restaura e persiste uma escolha válida na tela de título e usa seu sprite na rodada seguinte.

## Visão Geral

Quando `TitleView` abre, a tela lê `best_distance_km` e cria `TitleShipSelectionCubit`. O Cubit começa com a nave padrão e só restaura `title_player_ship` quando o ID ainda existe no catálogo e seu requisito foi alcançado.

O seletor exibe todas as skins, não apenas as liberadas. Cada tile mostra sprite, nome localizado e estado; naves bloqueadas não respondem ao toque. Selecionar uma nave liberada persiste o ID e atualiza hero, botão e parâmetro de início.

`GamePage` repassa a skin a `ArcadeOne`, que carrega o caminho escolhido e injeta a imagem em `Ship`. Se o arquivo não puder ser resolvido, a entidade mantém o fallback procedural.

## Passo a Passo

1. **Criação do estado** — `lib/title/view/title_page.dart` → `_TitleViewState.initState`
   Obtém o `StorageService`, cria `TitleShipSelectionCubit` e dispara `_initShipSelection`.
2. **Leitura do recorde** — `lib/title/view/title_page.dart` → `_initShipSelection`
   Lê `best_distance_km`, atualiza `_bestDistanceKm` e chama `TitleShipSelectionCubit.init`.
3. **Restauração validada** — `lib/title/cubit/title_ship_selection_cubit.dart` → `init`
   Lê `title_player_ship`, busca o ID no catálogo e só emite a skin se ela existir e estiver desbloqueada.
4. **Apresentação atual** — `lib/title/content/title_main_content.dart` → `TitleMainContent.build`
   Entrega a skin selecionada ao hero, ao botão de seleção e ao botão de início.
5. **Abertura do catálogo** — `lib/title/view/title_page.dart` → `_showShipSelectionSheet`
   Abre `TitleShipSelectionSheet` com a seleção e o recorde atuais.
6. **Cálculo por tile** — `lib/title/content/title_ship_selection_sheet.dart` → `_ShipSelectionTile`
   Percorre `playerShipSkins`, resolve o nome localizado e compara `unlockKm` com `bestDistanceKm` para exibir status e habilitar o toque.
7. **Persistência da escolha** — `lib/title/cubit/title_ship_selection_cubit.dart` → `setShip`
   Para uma nave liberada e diferente da atual, grava seu `id` em `title_player_ship` e emite a nova skin.
8. **Início configurado** — `lib/title/content/title_start_button.dart` → `onPressed`
   Cria `GamePage.route` com a `PlayerShipSkin` selecionada.
9. **Propagação à cena** — `lib/game/view/game_page.dart` → `GameView.build`
   Repassa a skin ao construtor de `ArcadeOne`.
10. **Carga e renderização** — `lib/game/arcade_one.dart` → `_loadGameImages` e `_buildRun`
    Carrega `playerShip.assetPath` e cria `Ship(shipImage: _playerShipImage)`.

### Caminhos alternativos

- **Nenhum ID salvo:** o Cubit mantém `defaultPlayerShipSkin`.
- **ID desconhecido:** `playerShipSkinById` retorna a nave padrão, mas a comparação com o ID salvo impede que esse fallback seja emitido como restauração válida.
- **Nave salva ainda bloqueada:** o Cubit ignora a preferência e mantém a padrão.
- **Toque em nave bloqueada:** o tile recebe `onTap: null` e não chama o Cubit.
- **Sprite não carregado:** `Ship` desenha a nave procedural em canvas.

## Arquivos Envolvidos

| Camada | Arquivo | Responsabilidade |
|--------|---------|------------------|
| Modelo | `lib/game/player_ship/player_ship_skin.dart` | Define ID, caminho do asset e requisito de distância. |
| Catálogo | `lib/game/player_ship/player_ship_catalog.dart` | Ordena skins, resolve IDs, desbloqueios e nomes localizados. |
| Estado | `lib/title/cubit/title_ship_selection_cubit.dart` | Restaura, valida, persiste e publica a seleção. |
| Apresentação | `lib/title/view/title_page.dart` | Lê o recorde, fornece o Cubit e abre o seletor. |
| Apresentação | `lib/title/content/title_ship_selection_sheet.dart` | Lista estados de seleção e bloqueio. |
| Apresentação | `lib/title/content/title_hero.dart` | Mostra o sprite escolhido no destaque da tela. |
| Navegação | `lib/title/content/title_start_button.dart` | Transporta a skin para a rota do jogo. |
| Gameplay | `lib/game/view/game_page.dart` | Transporta a skin até `ArcadeOne`. |
| Gameplay | `lib/game/arcade_one.dart` | Carrega o asset escolhido e cria `Ship`. |
| Dados | `lib/common/services/storage_service.dart` | Lê recorde e persiste o ID. |
| Testes | `test/game/player_ship/player_ship_catalog_test.dart` | Cobre limiares, lista liberada e fallback de ID. |
| Testes | `test/title/cubit/title_ship_selection_cubit_test.dart` | Cobre restauração, bloqueios e persistência. |
| Testes | `test/title/view/title_page_test.dart` | Cobre abertura, seleção e parâmetro da rota. |
| Testes | `test/game/view/game_page_test.dart` | Cobre propagação da skin para `GameView`. |
| Testes | `test/game/arcade_one_test.dart` | Cobre carga do asset selecionado. |

## Regras de Negócio Relevantes

- **Nave padrão sempre liberada** — `lib/game/player_ship/player_ship_catalog.dart`: `default` exige `0 km`.
- **Desbloqueios por recorde** — `lib/game/player_ship/player_ship_catalog.dart`: requisitos são `250`, `600`, `1000`, `1500`, `2100`, `2800`, `3600`, `4500`, `5600`, `7000` e `8500` km.
- **Persistência somente de escolha válida** — `lib/title/cubit/title_ship_selection_cubit.dart`: uma skin bloqueada ou já ativa não é gravada.
- **Validação na restauração** — `lib/title/cubit/title_ship_selection_cubit.dart`: a preferência precisa apontar para ID conhecido e desbloqueado no recorde atual.
- **Nomes localizados por ID** — `lib/game/player_ship/player_ship_catalog.dart`: cada skin resolve uma chave específica de `AppLocalizations`.

## Dependências Externas

- `flutter_bloc` para o Cubit local da tela de título.
- Flame para carregar e renderizar o sprite selecionado na cena.
- `shared_preferences`, via `StorageService`, para recorde e escolha.

## Observações

- O catálogo de skins repete manualmente os limiares de `spaceLandmarks`; não há referência de dados direta entre os catálogos.
- `TitleView` lê o recorde uma vez por instância. Ao voltar do game over, uma nova rota de título é construída e consulta o recorde atualizado.

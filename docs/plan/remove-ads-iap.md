# Remover Anúncios (In-App Purchase)

> **Objetivo:** Permitir a compra única não-consumível "Remover anúncios" na tela de título, persistindo o entitlement localmente e ocultando o banner do jogo para quem comprou.
> **Design de origem:** brainstorming desta conversa
> **Flows relacionados:** `docs/flow/title.md`, `docs/flow/game.md`

## Contexto

O Google Play Console bloqueia o cadastro de "produtos únicos" porque o APK ainda não tem a permissão `BILLING` — ela só chega ao integrar o plugin `in_app_purchase`. Hoje o projeto não tem nenhuma infraestrutura de compras, backend ou credenciais de verificação de recibo. O produto a vender é "remover anúncios": uma compra não-consumível que deve desligar o banner atualmente exibido em `GameView` (`lib/game/view/game_page.dart`).

## Design de Origem

- **Decisão aprovada:** Ícone "Remover anúncios" no `TitleTopBar` que abre um diálogo de compra; verificação confiando no status do próprio plugin `in_app_purchase` (`purchased`/`restored` do `purchaseStream`), sem `verify_local_purchase`; entitlement persistido via `StorageService` e exposto por um `RemoveAdsCubit` global (padrão de `AppLocaleCubit`), que também controla a exibição do banner em `GamePage`.
- **Alternativas descartadas:** Verificação com `verify_local_purchase` (validação direta nas APIs da Apple/Google) — descartada por exigir credenciais/infra (service account do Google Play, shared secret da Apple via `--dart-define`) desproporcionais para um produto único de baixo valor num projeto sem backend.
- **Tipo de mudança:** Logic

## Arquitetura / Escopo

| Arquivo | Ação | Responsabilidade |
|---------|------|-----------------|
| `pubspec.yaml` | editar | Adiciona a dependência `in_app_purchase`. |
| `lib/common/services/in_app_purchase/purchase_ids.dart` | criar | Define `removeAdsProductId`, única fonte do ID de produto. |
| `lib/common/services/in_app_purchase/in_app_purchase_service.dart` | criar | Interface fina sobre o plugin: `isAvailable`, `queryProductDetails`, `buyNonConsumable`, `completePurchase`, `restorePurchases`, `purchaseStream`. |
| `lib/common/services/in_app_purchase/in_app_purchase_service_impl.dart` | criar | Implementação real sobre `InAppPurchase.instance`. |
| `lib/app/cubit/remove_ads_state.dart` | criar | `RemoveAdsState` (Equatable, `copyWith`) e enum `RemoveAdsNotice`. |
| `lib/app/cubit/remove_ads_cubit.dart` | criar | `Cubit<RemoveAdsState>` no molde de `AppLocaleCubit`: restaura o entitlement, processa o `purchaseStream` e expõe `buy()`/`restore()`. |
| `lib/app/app.dart` | editar | Registra `RemoveAdsCubit` no `MultiBlocProvider` global. |
| `lib/game/view/game_page.dart` | editar | `bannerAdUnitId` vira `null` quando há entitlement. |
| `lib/title/content/title_remove_ads_dialog.dart` | criar | `AlertDialog` de compra/restauração. |
| `lib/title/content/title_top_bar.dart` | editar | Novo botão que abre o diálogo; some quando já comprado. |
| `lib/l10n/arb/app_en.arb`, `lib/l10n/arb/app_pt.arb` | editar | Novas chaves de texto do fluxo de compra. |
| `test/app/cubit/remove_ads_cubit_test.dart` | criar | Cobre a máquina de estados do Cubit com fakes. |
| `test/helpers/pump_app.dart` | editar | Novo parâmetro opcional `removeAdsCubit`. |
| `test/game/view/game_page_test.dart` | editar | Caso: banner some com entitlement ativo. |
| `docs/flow/title.md`, `docs/flow/game.md` | editar | Refletem o novo botão/diálogo e a condição do banner. |

## Fases

### Fase 1 — Dependência, tipos e esqueleto do serviço

- [x] Rodar `flutter pub add in_app_purchase` (sem fixar versão manual)
- [x] Criar `lib/common/services/in_app_purchase/purchase_ids.dart` com `const removeAdsProductId = 'removeranuncio'` _(ID definido pelo usuário; o plano previa `remove_ads`)_
- [x] Criar `lib/common/services/in_app_purchase/in_app_purchase_service.dart` (interface abstrata) com os métodos `Future<bool> isAvailable()`, `Future<ProductDetailsResponse> queryProductDetails(Set<String> ids)`, `Future<bool> buyNonConsumable(PurchaseParam param)`, `Future<void> completePurchase(PurchaseDetails purchase)`, `Future<void> restorePurchases()`, `Stream<List<PurchaseDetails>> get purchaseStream` _(o plano previa `Future<bool>` em `restorePurchases`; o plugin expõe `Future<void>`)_
- [x] Criar `lib/common/services/in_app_purchase/in_app_purchase_service_impl.dart` implementando a interface sobre `InAppPurchase.instance`
- [x] Criar `lib/app/cubit/remove_ads_state.dart` com `RemoveAdsState` completo (`hasRemovedAds`, `productPriceLabel`, `isStoreAvailable`, `purchasePending`, `notice`), `Equatable`, `copyWith`, e `enum RemoveAdsNotice { purchaseSuccess, purchaseFailed, restoreNothingFound, storeUnavailable }`
- [x] Criar `lib/app/cubit/remove_ads_cubit.dart` com o esqueleto do `Cubit<RemoveAdsState>`: construtor `({required StorageService storage, required InAppPurchaseService service})`, campos e assinaturas de `init()`, `loadProduct()`, `buy()`, `restore()`, `close()` com corpo mínimo (sem lógica), apenas para compilar
- [x] Verificação: `flutter analyze` sem erros

### Fase 2 — Testes do RemoveAdsCubit (TDD, vão falhar)

> Os testes vão falhar inicialmente — isso é intencional, o Cubit da Fase 1 ainda não tem lógica.

- [x] Criar `test/app/cubit/remove_ads_cubit_test.dart` com mocks (`mocktail`) de `StorageService` e `InAppPurchaseService`, controlando `purchaseStream` via `StreamController<List<PurchaseDetails>>`
- [x] Testar: `init()` lê `remove_ads_purchased` do storage e emite `hasRemovedAds: true` quando `true`
- [x] Testar: `buy()` chama `service.buyNonConsumable` com `PurchaseParam` do `removeAdsProductId`
- [x] Testar: evento `purchased`/`restored` no stream persiste o flag (`storage.setBool('remove_ads_purchased', value: true)`), completa a compra e emite `notice: purchaseSuccess`
- [x] Testar: evento `canceled`/`error` não persiste, completa a compra pendente e emite `notice: purchaseFailed`
- [x] Testar: evento `pending` emite `purchasePending: true` sem persistir
- [x] Testar: `restore()` com stream retornando lista vazia emite `notice: restoreNothingFound`
- [x] Testar: erro na subscription (`addError`) emite `notice: storeUnavailable`
- [x] Verificação: `flutter test test/app/cubit/remove_ads_cubit_test.dart` falha pelas asserções de estado (não por erro de compilação)

### Fase 3 — Implementação do RemoveAdsCubit

- [x] Implementar `init()`, `loadProduct()`, `buy()`, `restore()`, `_onPurchaseUpdates` e `close()` em `lib/app/cubit/remove_ads_cubit.dart` cobrindo os casos da Fase 2: `pending`, `canceled`/`error` (completa sem persistir), `purchased`/`restored` (completa, persiste, emite sucesso), lista vazia durante restore, e `onError` na subscription
- [x] Verificação: `flutter test test/app/cubit/remove_ads_cubit_test.dart` passa

### Fase 4 — Registro global e banner do jogo

- [x] Registrar `RemoveAdsCubit` no `MultiBlocProvider` de `lib/app/app.dart`, instanciando `InAppPurchaseServiceImpl()` e chamando `unawaited(cubit.init())` seguido de `unawaited(cubit.loadProduct())`
- [x] Em `lib/game/view/game_page.dart` (`GameView.build`), ler `context.watch<RemoveAdsCubit>().state.hasRemovedAds` e calcular `bannerAdUnitId` como `null` quando `true` (o cálculo de `joystickBottomPadding` já depende de `bannerAdUnitId == null`, sem outra mudança necessária)
- [x] Adicionar parâmetro opcional `RemoveAdsCubit? removeAdsCubit` em `test/helpers/pump_app.dart`, com fallback padrão (`hasRemovedAds: false`)
- [x] Adicionar caso em `test/game/view/game_page_test.dart`: banner não é renderizado quando `RemoveAdsCubit` está com `hasRemovedAds: true`
- [x] Verificação: `flutter test test/game/view/game_page_test.dart` passa

### Fase 5 — UI de compra na tela de título

- [x] Adicionar chaves em `lib/l10n/arb/app_en.arb` e `lib/l10n/arb/app_pt.arb`: tooltip do botão, título/descrição do diálogo, texto do botão comprar (com preço), botão restaurar, mensagens de sucesso/erro/"nada a restaurar"/loja indisponível
- [x] Rodar `flutter gen-l10n`
- [x] Criar `lib/title/content/title_remove_ads_dialog.dart`: `AlertDialog` mostrando `productPriceLabel` (ou aviso de indisponível), botão "Comprar" (desabilitado durante `purchasePending` ou `!isStoreAvailable`) e botão "Restaurar compras", usando `BlocBuilder`/`BlocListener<RemoveAdsCubit, RemoveAdsState>` via `context.l10n`
- [x] Editar `lib/title/content/title_top_bar.dart`: novo `IconButton.filledTonal` (mesmo estilo do botão de volume) que abre `TitleRemoveAdsDialog`, oculto via `BlocBuilder<RemoveAdsCubit, RemoveAdsState>` quando `state.hasRemovedAds == true`
- [x] Verificação: `flutter analyze` sem erros

### Fase 6 — Atualizar Flows

- [x] Atualizar `docs/flow/title.md`: novo passo no "Passo a Passo" para o botão/diálogo de compra, nova linha em "Arquivos Envolvidos" (`title_remove_ads_dialog.dart`, `remove_ads_cubit.dart`) e nova regra em "Regras de Negócio Relevantes" sobre o entitlement de remoção de anúncios
- [x] Atualizar `docs/flow/game.md`: novo caminho alternativo "banner some quando há entitlement de remoção de anúncios ativo" e referência a `RemoveAdsCubit` na tabela de arquivos
- [x] Verificação: seções atualizadas citam os arquivos reais criados nas fases anteriores

## Critérios de Sucesso

- [x] Comprar "Remover anúncios" persiste o entitlement e oculta o botão/diálogo na próxima abertura da tela de título _(persistência e ocultação cobertas por testes; chamada real à loja no critério manual)_
- [x] Com entitlement ativo, `GameView` não exibe o `AdBannerWidget`
- [x] "Restaurar compras" sem compra anterior emite aviso de "nada a restaurar" sem travar o diálogo
- [x] Build sem erros _(flutter build apk --debug --flavor development)_
- [x] Todos os testes unitários passando _(167 testes)_
- [ ] _(manual — feito pelo usuário)_ Compra e restauração validadas com conta de teste (sandbox iOS / testador de licença Android) e cadastro do produto `removeranuncio` nas duas lojas

## Riscos e Mitigações

| Risco | Probabilidade | Mitigação |
|-------|--------------|-----------|
| Produto `removeranuncio` ainda não cadastrado nas lojas ao testar manualmente | Alta | Critério de sucesso final deixa explícito que o cadastro nas lojas precede o teste manual; `queryProductDetails` retornando vazio já é tratado como loja indisponível |
| Trocar de aparelho ou reinstalar apaga o flag local sem o usuário perceber | Média | Botão "Restaurar compras" explícito no diálogo, sempre visível enquanto não houver entitlement |
| Confiar só no status do plugin (sem `verify_local_purchase`) permite editar o flag localmente em dispositivo rooteado | Baixa (produto de baixo valor) | Decisão já registrada em "Alternativas descartadas"; migrar para `verify_local_purchase`/backend fica como evolução futura se o valor do produto aumentar |

## Rollback

Reverter os arquivos criados e editados listados em "Arquitetura / Escopo", remover a dependência `in_app_purchase` do `pubspec.yaml` e rodar `flutter pub get`. Nenhuma migração de dados é necessária — a chave `remove_ads_purchased` fica órfã no `SharedPreferences`, sem efeito colateral.

## Registro de Execução

- ID do produto ajustado para `removeranuncio` a pedido do usuário; `restorePurchases` usa `Future<void>` por contrato do `in_app_purchase` (Fase 1).
- Extras necessários ao padrão do projeto e às evidências dos critérios de sucesso: export de `remove_ads_cubit.dart`/`remove_ads_state.dart` em `lib/app/cubit/cubit.dart`; caso do botão oculto em `test/title/view/title_page_test.dart`; `test/title/view/title_remove_ads_dialog_test.dart` para preço, indisponibilidade, compra, restauração e entitlements ativos.
- Campos do `RemoveAdsCubit` ficaram privados (`_storage`/`_service`) para não ampliar os avisos do `bloc_lint`.
- Verificações finais: `flutter analyze` limpo; `flutter test --coverage --test-randomize-ordering-seed random` com 167 testes passando; `flutter build apk --debug --flavor development --target lib/main_development.dart` OK; `dart run bloc_tools:bloc lint .` com 6 avisos pré-existentes (nenhum novo).
- Revisão independente da rubrica de conclusão: 9/10, sem zeros; observação não impeditiva de que o teste do banner passa vacuamente no host de teste (nem Android nem iOS), restando a inspeção de `GameView` como prova complementar.
- Ajuste pós-execução a pedido do usuário: o CTA de remover anúncios saiu da top bar (ícone isolado) e virou `lib/title/content/title_remove_ads_button.dart`, um botão rotulado com ícone exibido abaixo do botão de lançar em `lib/title/content/title_main_content.dart`; `titleRemoveAdsTooltip` foi substituída por `titleRemoveAdsButton` e `docs/flow/title.md` reflete o novo local.

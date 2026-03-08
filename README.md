# outlaw_reputation - Hub de réputation ESX (FiveM)

Système modulaire de réputation pour FiveM/ESX avec API centralisée (exports, events, DB), NUI, permissions, anti-abus et intégrations automatiques.

## Installation

1. Copier le dossier `outlaw_reputation` dans vos resources.
2. Importer `outlaw_reputation/sql/schema.sql` dans votre base.
3. Vérifier vos dépendances: `es_extended`, `oxmysql`.
4. Ajouter à votre `server.cfg` :

```cfg
ensure outlaw_reputation
```

## Types de réputation

Définis dans `config/config_rep_types.lua`:
- business
- crime
- police
- gang
- extensible avec vos propres clés

## API serveur

### Exports

```lua
exports.outlaw_reputation:addRep(playerId, type, amount, reason)
exports.outlaw_reputation:getRep(playerId, type)
exports.outlaw_reputation:setRep(playerId, type, value)
```

### Event

```lua
TriggerEvent('outlaw_rep:add', playerId, type, amount, 'raison métier')
```

## Flux demande / acceptation

Commande:

```txt
/outlawrep [playerID] [type]
```

- Le demandeur doit avoir les permissions (job/grade).
- La cible reçoit un popup NUI avec Accept/Decline.
- En cas d’acceptation, le demandeur voit le tableau complet.

## Intégrations automatiques

Le système détecte l’état des ressources:
- `esx_billing`
- `okokBilling`
- `esx_drugs`

Chaque connecteur applique la logique configurée dans `config/config_integrations.lua`.

## Scripts personnalisés

- `config/config_custom_scripts.lua` supporte un polling SQL custom (`CustomBilling`).
- `CustomIntegrations` permet d’ajouter des événements perso sans toucher le core.

## Anti-abus

- Cap journalier par type.
- Limitation des interactions source -> cible.
- Décroissance des gains en cas de répétition.

## NUI

Panneaux disponibles:
- Réputation joueur
- Réputation entreprise + contributions
- Leaderboard
- Dossier police

Commande utile côté joueur (sans permission):

```txt
/myrep
```

La commande récupère vos données via votre identifiant `license` et affiche `0` pour les types de réputation non initialisés.

## Scénarios d’usage

1. **Garage** : un mécano facture via `esx_billing`, gagne automatiquement de la réputation business.
2. **Crime** : vente via `esx_drugs` augmente la réputation crime et met à jour le snapshot police.
3. **Police** : un chef police demande la réputation crime d’un suspect via `/outlawrep 12 crime`.
4. **Script perso** : un événement custom ajoute de la réputation gang via `CustomIntegrations`.

## Structure

Voir l’arborescence demandée dans `outlaw_reputation/`.

# Club 8 Pool — App Arbitre

Application mobile **Flutter** pour les arbitres de la Fédération Gabonaise de Billard. Consomme l'API Sanctum du monolithe [marseven/club8pool](https://github.com/marseven/club8pool).

## Écrans

1. **Login** — carte FGB + PIN
2. **File des matchs** — matchs assignés du jour (live, prochain, terminé)
3. **Pré-match** — choix du break, réglages (race, shot clock, alterné)
4. **En match** — shot clock 30s, chrono match, scoring frame par frame
5. **Fin de match** — signatures double, validation
6. **Hors-ligne** — file de synchro avec retries

## Direction graphique

Identique au monolithe web : noir profond, vert craie (`#2DA876`), typo Antonio + JetBrains Mono + Manrope (via `google_fonts`). Voir `lib/theme/`.

## Démarrage

```bash
flutter pub get
flutter run
```

L'app cible **https://club8pool.com/api** par défaut. Pour pointer vers un serveur local en dev :

```bash
flutter run --dart-define=API_BASE=http://10.0.2.2:8089/api      # Android emulator
flutter run --dart-define=API_BASE=http://localhost:8089/api     # iOS simulator
```

## Comptes de démo

| Arbitre | Carte FGB | PIN |
| --- | --- | --- |
| Eric | `ICN-ARB-001` | `12345` |
| T-One | `ICN-ARB-002` | `12345` |

## Structure

```
lib/
  main.dart                  # routes + splash
  services/api.dart          # Dio client + persistance token
  theme/                     # colors + typo
  widgets/                   # Ball8, GabonFlag
  screens/
    login_screen.dart
    queue_screen.dart
    pre_match_screen.dart
    live_match_screen.dart
    end_match_screen.dart
    offline_screen.dart
```

## Dépendances

- `dio` — client HTTP
- `shared_preferences` — persistance du token Sanctum
- `google_fonts` — Antonio / JetBrains Mono / Manrope
- `go_router` (réservé pour expansion future)

## Crédits

Design : Claude Design exploration. Implémentation : [@marseven](https://github.com/marseven).

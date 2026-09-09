# camera_plugins_fork

Fork pinado de dois plugins do `flutter/packages` para o vik-app. Cópias literais dos pacotes publicados no pub.dev, com um patch cada, marcado no código com `Fork VIK`.

| Pacote | Base | Patch |
| --- | --- | --- |
| `camera_android_camerax` | 0.6.30 (tag `camera_android_camerax-v0.6.30`) | `ResolutionPreset.veryHigh` vira 4:3 com limite 1920×1440, em vez de 16:9 1920×1080. |
| `camera_avfoundation` | 0.9.23+2 (tag `camera_avfoundation-v0.9.23+2`) | `veryHigh` escolhe o formato 4:3 de maior resolução com lado maior até 1920; a saída de foto pede `photoQualityPrioritization = .quality`. |

Motivo: a câmera in-app do comprovante de atividade abria em 16:9 e descartava 25% do campo lateral do sensor em pé, o que a comunidade lia como "zoom" (card ClickUp 86akfrx6z). Nenhum preset de upstream entrega 4:3 em resolução útil, e `max` abre o sensor inteiro no preview.

Como consumir no app (`pubspec.yaml`):

```yaml
dependency_overrides:
  camera_android_camerax:
    git:
      url: https://github.com/desafiovik/camera_plugins_fork
      path: camera_android_camerax
      ref: <commit>
  camera_avfoundation:
    git:
      url: https://github.com/desafiovik/camera_plugins_fork
      path: camera_avfoundation
      ref: <commit>
```

Ao subir a versão de base, reaplique o patch procurando por `Fork VIK` nos dois pacotes e rode `flutter test` em `camera_android_camerax` e o alvo `RunnerTests` do exemplo de `camera_avfoundation` no Xcode.

Licença dos pacotes: BSD-3 dos Flutter Authors, preservada em cada diretório.

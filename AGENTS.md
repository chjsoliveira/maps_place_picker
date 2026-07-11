# Agents — instruções deste repositório

Este pacote é publicado no pub.dev. Score de pub e experiência de quem instala
a dependência importam tanto quanto o código.

## Regra obrigatória: CHANGELOG.md

**Toda alteração relevante neste repositório (feature, fix, bump de
dependência, mudança de CI, ou qualquer coisa que mude o comportamento ou o
score do pacote) precisa de uma entrada correspondente em `CHANGELOG.md`.**

- Confira `pubspec.yaml` antes de decidir se abre uma versão nova ou entra na
  seção já existente: se a versão do topo do `CHANGELOG.md` ainda não tem tag
  `git tag` correspondente (`git tag -l`), ela ainda não foi publicada — some
  a mudança na seção existente em vez de criar uma nova.
- Se a versão do topo já foi tageada/publicada, crie uma nova seção
  `## [x.y.z] - DD/Mon/YYYY` (mesmo formato de data usado nas entradas
  anteriores) e bump a versão em `pubspec.yaml`.
- Agrupe por categoria consistente com o histórico: `### Features`,
  `### Bug fixes`, `### Dependencies`, `### Docs / maintenance`,
  `### CI / maintenance`, `### ⚠️ Breaking changes`.
- Descreva o *porquê*, não só o *o quê* — especialmente em bug fixes, explique
  a condição que causava o problema.

## Score do pub.dev

- `doc/preview.gif` (referenciado em `screenshots:` no `pubspec.yaml`) tem
  limite de 4 MB imposto pelo pub.dev. Se for necessário regenerar o GIF,
  comprima com paleta otimizada em vez de só reduzir fps/escala:

  ```bash
  ffmpeg -y -i doc/preview.gif \
    -vf "fps=8,scale=280:-1:flags=lanczos,palettegen=max_colors=128" \
    -update 1 doc/palette.png

  ffmpeg -y -i doc/preview.gif -i doc/palette.png \
    -lavfi "fps=8,scale=280:-1:flags=lanczos[x];[x][1:v]paletteuse=dither=bayer:bayer_scale=5" \
    doc/preview-small.gif

  mv doc/preview-small.gif doc/preview.gif
  rm doc/palette.png
  ```

  Mire em ficar bem abaixo do limite (ex.: ~2.5 MB), não só abaixo por pouco —
  o vídeo de origem cresce com o tempo. Ajuste `fps`/`scale`/`max_colors` para
  baixo até o tamanho ficar confortável, e confira o resultado (ex.: lendo o
  gif) antes de descartar o original.
- Antes de publicar, rode `flutter analyze` e `flutter test` (ambos devem
  passar) e, se possível, `flutter pub publish --dry-run` para pegar
  problemas de score antes do pub.dev.
- `flutter pub upgrade` roda semanalmente via
  `.github/workflows/update-packages.yml` e abre PR automática — ao revisar
  ou mesclar essas PRs, adicione a entrada de `CHANGELOG.md` manualmente (o
  workflow não faz isso).

## Publicação

A publicação real (`v${version}` tag + `flutter pub publish`) acontece via
`.github/workflows/release.yml`, disparado manualmente
(`workflow_dispatch`). Não rode `flutter pub publish` localmente sem pedido
explícito do usuário — a versão e a tag devem vir do workflow.

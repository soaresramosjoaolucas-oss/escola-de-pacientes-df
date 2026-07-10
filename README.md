# Escola de Pacientes DF — site

Site estático da **Escola de Pacientes DF**, estratégia de integração ensino-serviço-comunidade
ativa desde 2016 no Distrito Federal (UnB · SES-DF), coordenada pelo Prof. Dr. Estêvão Cubas Rolim.

O site é publicado pelo GitHub Pages a partir da pasta [`docs/`](docs/).

## Estrutura

```
build/
  manifest.txt      # slug | título | categoria | grupo — taxonomia das páginas (breadcrumb/busca)
  build.pl          # gerador: converte build/content*/ em HTML dentro de docs/
                    #   · o MENU principal é a estrutura @NAV no topo do build.pl (curado, enxuto)
                    #   · gera também /temas (índice de temas) e /az (índice A–Z do acervo)
  landing.html      # template da página inicial (vitrine institucional)
  vitrine-dados.md  # dados curados da vitrine (publicações, prêmios, reportagens, trajetória)
  assets/           # CSS, JS de busca e imagens copiados para docs/assets/
  content/          # conteúdo das páginas principais (markdown simplificado)
  content2/         # conteúdo das subpáginas (nome de arquivo usa "__" como separador de pasta)
docs/               # SITE GERADO — não editar à mão
```

As páginas-portal por público ficam em `build/content/para-pacientes.md`, `para-estudantes.md`,
`para-pesquisadores.md` e `para-profissionais.md`.

Para trocar as fotos: substitua os arquivos em `build/assets/img/` (`logo.png`, `dr-estevao.jpg`,
`unb-fm.jpg`) mantendo os nomes, e rode o gerador novamente.

## Como editar

1. Edite o conteúdo em `build/content/` ou `build/content2/` (ou os templates em `build/`).
2. Gere o site novamente:
   ```sh
   perl build/build.pl
   ```
3. Faça commit e push — o GitHub Pages publica automaticamente.

### Formato do conteúdo

- `# Título` — título da página (aparece no cabeçalho)
- `## Seção` / linha TODA EM MAIÚSCULAS — subtítulos
- `- item` — lista
- `[texto](url)` — link
- `[EMBED: rótulo](url)` — arquivo do Drive, documento Google, pasta ou vídeo do YouTube embutido

### Para adicionar uma página nova

1. Crie `build/content/minha-pagina.md`.
2. Acrescente uma linha em `build/manifest.txt` com a categoria desejada.
3. Rode `perl build/build.pl`.

## Origem do conteúdo

Conteúdo migrado do site original em Google Sites (escoladepacientes.com) em julho de 2026.

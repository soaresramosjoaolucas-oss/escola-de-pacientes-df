#!/usr/bin/perl
# Gerador do site estático da Escola de Pacientes DF.
# Lê build/content/*.md (páginas) e build/content2/*.md (subpáginas, nome com "__"),
# aplica o manifesto de categorias e escreve o site pronto em docs/.
use strict; use warnings; use utf8;
use open ':std', ':encoding(UTF-8)';
use File::Path qw(make_path);
use File::Basename qw(dirname);
use URI::Escape qw(uri_unescape);

my $ROOT   = dirname(__FILE__);
my $OUT    = "$ROOT/../docs";
my $SITE   = 'Escola de Pacientes DF';

# ---------------- manifesto ----------------
my (%page, @order);          # slug -> {title, cat, group}
open my $mf, '<:encoding(UTF-8)', "$ROOT/manifest.txt" or die $!;
while (<$mf>) {
    chomp; next if /^\s*#/ or /^\s*$/;
    my ($slug, $title, $cat, $group) = split /\|/;
    $page{$slug} = { title => $title, cat => $cat, group => $group // '' };
    push @order, $slug;
}
close $mf;

my %cat_label = (
    sobre         => 'A Escola',
    ensino        => 'Ensino UnB',
    pratica       => 'Simulações e Testes',
    temas         => 'Temas Clínicos',
    pacientes     => 'Educação em Saúde',
    profissionais => 'Profissionais e Gestão',
    ciencia       => 'Ciência',
    noticias      => 'Notícias e Mídia',
    projetos      => 'Projetos e Produtos',
    publicos      => 'Comece por aqui',
);
my @group_order = ('Doenças crônicas', 'Saúde da mulher e pré-natal', 'Saúde mental e bem-estar',
                   'Infecções e urgências', 'Outros temas');

# menu principal curado — vitrine, não inventário
my @NAV = (
    { label => 'A Escola', items => [
        ['boas-vindas', 'Quem somos'],
        ['dr-estevao-rolim', 'Dr. Estêvão Rolim'],
        ['equipe', 'Equipe e Grupo de Pesquisa'],
        ['premios', 'Prêmios e Reconhecimentos'],
        ['reportagens', 'Na Mídia'],
        ['historia-da-medicina', 'História da Medicina'],
        ['planejamento-estrategico', 'Planejamento Estratégico'],
        ['diagnostico-situacional', 'Diagnóstico Situacional'],
        ['painel-de-bordo', 'Painel de Bordo'],
        ['agenda-2030-ods-3-saude', 'Agenda 2030 — ODS 3'],
    ]},
    { label => 'Projetos e Produtos', items => [
        ['receita-simples', 'Receita Simples'],
        ['simulacoes', 'Simulações e Pacientes Digitais'],
        ['prescreva-um-livro', 'Prescreva um Livro'],
        ['escola-saudavel', 'Escola Saudável'],
        ['youtube', 'Canal no YouTube'],
        ['impressos-de-educacao-em-saude', 'Materiais Educativos'],
    ]},
    { label => 'Comece por aqui', items => [
        ['para-pacientes', '🧑‍🦱 Pacientes e Comunidade'],
        ['para-estudantes', '🎓 Estudantes'],
        ['para-pesquisadores', '🔬 Pesquisadores'],
        ['para-profissionais', '🩺 Profissionais e Gestores'],
    ]},
    { label => 'Ciência', items => [
        ['publicacoes', 'Publicações'],
        ['congressos', 'Congressos'],
        ['icase-2026', 'ICASE 2026'],
        ['ciencia-banco-de-citacoes', 'Banco de Citações'],
        ['cbpr-pesquisa-participativa-baseada-na-comunidade', 'Pesquisa Participativa (CBPR)'],
        ['rayyan-revisao-de-literatura', 'Rayyan — Revisão de Literatura'],
        ['ciencia-onde-buscar-referencias', 'Onde Buscar Referências'],
        ['ciencia-qualis-saude-coletiva', 'Qualis Saúde Coletiva'],
    ]},
    { label => 'Acervo', items => [
        ['temas', 'Temas Clínicos'],
        ['az', 'Índice A–Z (todas as páginas)'],
        ['testes', 'Testes'],
        ['noticias', 'Notícias'],
    ]},
);

# ---------------- conteúdo ----------------
my %content;                 # path (ex.: "hipertensao" ou "testes/teste-x") -> md
for my $f (glob "$ROOT/content/*.md") {
    my ($slug) = $f =~ m{([^/\\]+)\.md$};
    next if $slug eq 'home';
    open my $fh, '<:encoding(UTF-8)', $f or die $!;
    local $/; $content{$slug} = <$fh>;
}
for my $f (glob "$ROOT/content2/*.md") {
    my ($name) = $f =~ m{([^/\\]+)\.md$};
    (my $path = $name) =~ s/__/\//g;
    open my $fh, '<:encoding(UTF-8)', $f or die $!;
    local $/; $content{$path} = <$fh>;
}

# filhos por página-mãe
my %children;
for my $path (sort keys %content) {
    next unless $path =~ m{^([^/]+)/(.+)$};
    push @{ $children{$1} }, $path;
}

# título de uma página (manifesto > h1 do conteúdo > slug)
sub title_of {
    my ($path) = @_;
    return $page{$path}{title} if $page{$path} && $page{$path}{title};
    if (defined $content{$path} && $content{$path} =~ /^#\s+(.+?)\s*$/m) {
        my $t = $1; $t =~ s/<[^>]+>//g;
        return $t if length $t;
    }
    my $t = (split m{/}, $path)[-1];
    $t =~ s/-/ /g; return ucfirst $t;
}

# ---------------- helpers HTML ----------------
sub esc { my $s = shift; $s =~ s/&/&amp;/g; $s =~ s/</&lt;/g; $s =~ s/>/&gt;/g; $s }

sub clean_url {
    my ($u, $p) = @_;
    # desembrulha redirecionador do Google
    if ($u =~ m{^https?://www\.google\.com/url\?q=([^&]+)}) {
        $u = uri_unescape($1);
    }
    # links internos do site antigo -> páginas novas
    $u =~ s{^https?://(?:www\.)?escoladepacientes\.com}{};
    if ($u =~ m{^/}) {
        (my $path = $u) =~ s{^/}{}; $path =~ s{[#?].*$}{};
        $path =~ s{/$}{};
        if ($path eq '' or $path eq 'home') { return $p eq '' ? './' : $p; }
        return "$p$path/" if exists $content{$path} or $path eq 'temas' or $path eq 'az';
        return "http://www.escoladepacientes.com/$path";   # não migrada: aponta pro antigo
    }
    return $u;
}

sub embed_html {
    my ($label, $url) = @_;
    $label =~ s/^(?:Drive|Document|Presentation|Spreadsheet|YouTube Video)\s*,\s*//i;
    my $l = esc($label);
    if ($url =~ m{youtube\.com/embed/([\w-]+)}) {
        my $src = "https://www.youtube.com/embed/$1";
        return qq{<figure class="embed embed-video"><iframe src="$src" title="$l" loading="lazy" allowfullscreen></iframe>}
             . ($l ? qq{<figcaption class="embed-caption"><span>$l</span><a href="https://www.youtube.com/watch?v=$1" target="_blank" rel="noopener">Ver no YouTube ↗</a></figcaption>} : '')
             . qq{</figure>};
    }
    if ($url =~ m{drive\.google\.com/file/d/([\w-]+)}) {
        my $view = "https://drive.google.com/file/d/$1/view";
        return qq{<figure class="embed embed-doc"><iframe src="https://drive.google.com/file/d/$1/preview" title="$l" loading="lazy"></iframe><figcaption class="embed-caption"><span>$l</span><a href="$view" target="_blank" rel="noopener">Abrir no Drive ↗</a></figcaption></figure>};
    }
    if ($url =~ m{drive\.google\.com/embeddedfolderview\?id=([\w-]+)}) {
        my $view = "https://drive.google.com/drive/folders/$1";
        my $cap = $l || 'Pasta de arquivos';
        return qq{<figure class="embed embed-folder"><iframe src="https://drive.google.com/embeddedfolderview?id=$1#list" title="$cap" loading="lazy"></iframe><figcaption class="embed-caption"><span>$cap</span><a href="$view" target="_blank" rel="noopener">Abrir a pasta ↗</a></figcaption></figure>};
    }
    if ($url =~ m{docs\.google\.com/(document|presentation|spreadsheets)/d/([\w-]+)}) {
        my ($kind, $id) = ($1, $2);
        my $src  = $kind eq 'presentation' ? "https://docs.google.com/presentation/d/$id/embed" : "https://docs.google.com/$kind/d/$id/preview";
        my $view = "https://docs.google.com/$kind/d/$id/edit";
        return qq{<figure class="embed embed-doc"><iframe src="$src" title="$l" loading="lazy"></iframe><figcaption class="embed-caption"><span>$l</span><a href="$view" target="_blank" rel="noopener">Abrir o documento ↗</a></figcaption></figure>};
    }
    if ($url =~ m{docs\.google\.com/forms|forms\.gle}) {
        return qq{<p><a href="$url" target="_blank" rel="noopener">📝 $l (formulário)</a></p>};
    }
    # iframe genérico só com link
    return qq{<p><a href="$url" target="_blank" rel="noopener">$l ↗</a></p>};
}

sub inline_fmt {
    my ($line, $p) = @_;
    $line = esc($line);
    $line =~ s{\[([^\]\[]*)\]\(([^)\s]+)\)}{
        my ($t, $u) = ($1, $2); $u = clean_url($u, $p);
        my $ext = $u =~ m{^https?://} ? ' target="_blank" rel="noopener"' : '';
        $t =~ s/^\s+|\s+$//g;
        $t eq '' ? '' : qq{<a href="$u"$ext>$t</a>};
    }ge;
    $line =~ s{(?<!["'=>])(https?://[^\s<>"')]+)}{
        my $orig = $1;
        my $u = clean_url($orig, $p);
        my $ext = $u =~ m{^https?://} ? ' target="_blank" rel="noopener"' : '';
        qq{<a href="$u"$ext>$orig</a>};
    }ge;
    return $line;
}

# md simplificado -> HTML
sub md_to_html {
    my ($md, $p) = @_;
    my @lines = split /\n/, $md;
    my (@html, $inlist, $last_embed_label);
    my $first_h1 = 0;
    for (my $i = 0; $i <= $#lines; $i++) {
        my $l = $lines[$i];
        $l =~ s/^\s+|\s+$//g;
        next if $l eq '' or $l eq '.' or $l =~ /^\.+$/;
        next if $l =~ /^\[IMAGEM:/;
        # "-" sozinho: item de lista cujo texto vem na próxima linha
        if ($l eq '-') { next; }
        # primeira h1 = título da página (já no hero)
        if ($l =~ /^#\s+/ && !$first_h1) { $first_h1 = 1; next; }

        # embed
        if ($l =~ /^\[EMBED:\s*(.*?)\]\((\S+)\)$/) {
            my ($label, $url) = ($1, $2);
            push @html, '</ul>' and $inlist = 0 if $inlist;
            # rótulo genérico: usa a próxima linha curta como legenda
            if ($label =~ /^(?:Drive Folder|Drive)?$/i) {
                for (my $j = $i + 1; $j <= $#lines && $j <= $i + 2; $j++) {
                    my $nx = $lines[$j]; $nx =~ s/^\s+|\s+$//g;
                    next if $nx eq '';
                    if (length($nx) <= 80 && $nx !~ /https?:/ && $nx !~ /^\[/ && $nx !~ /^#/) {
                        ($label = $nx) =~ s/\s*[-–—:]\s*$//;
                        $i = $j;
                    }
                    last;
                }
            }
            push @html, embed_html($label, $url);
            $last_embed_label = $label; $last_embed_label =~ s/^(?:Drive|Document|Presentation|Spreadsheet|YouTube Video)\s*,\s*//i;
            next;
        }
        # legenda repetida logo após o embed
        if (defined $last_embed_label && length($l) > 3) {
            my ($a, $b) = (lc $l, lc $last_embed_label);
            if (index($b, $a) >= 0 or index($a, $b) >= 0) { $last_embed_label = undef; next; }
        }
        $last_embed_label = undef;

        if ($l =~ /^##\s+(.+)/)  { push @html, '</ul>' and $inlist = 0 if $inlist; push @html, '<h2>' . inline_fmt($1, $p) . '</h2>'; next; }
        if ($l =~ /^###+\s+(.+)/){ push @html, '</ul>' and $inlist = 0 if $inlist; push @html, '<h3>' . inline_fmt($1, $p) . '</h3>'; next; }

        # item de lista
        if ($l =~ /^-\s+(.+)/) {
            push @html, '<ul>' unless $inlist; $inlist = 1;
            push @html, '<li>' . inline_fmt($1, $p) . '</li>';
            next;
        }
        push @html, '</ul>' and $inlist = 0 if $inlist;

        # linha toda em maiúsculas = subtítulo visual
        my $letters = () = $l =~ /\p{L}/g;
        if ($letters >= 4 && length($l) <= 90 && $l !~ /https?:/ && $l !~ /\p{Ll}/ && $l =~ /\p{Lu}/) {
            push @html, '<h3>' . inline_fmt($l, $p) . '</h3>';
            next;
        }
        push @html, '<p>' . inline_fmt($l, $p) . '</p>';
    }
    push @html, '</ul>' if $inlist;
    return join "\n", @html;
}

# ---------------- navegação ----------------
sub nav_html {
    my ($p, $current_cat) = @_;
    my $h = qq{<ul>\n};
    my $cur = (!defined $current_cat || $current_cat eq 'inicio') ? ' aria-current="page"' : '';
    my $home = $p eq '' ? './' : $p;
    $h .= qq{<li><a href="$home"$cur>Início</a></li>\n};
    for my $sec (@NAV) {
        my ($first_slug) = @{ $sec->{items}[0] };
        my $active = defined $current_cat && grep { $_->[0] eq $current_cat } @{ $sec->{items} };
        my $cc = $active ? ' aria-current="page"' : '';
        $h .= qq{<li><a href="$p$first_slug/"$cc>$sec->{label} <span class="caret">▾</span></a>\n<div class="dropdown">\n};
        for my $it (@{ $sec->{items} }) {
            my ($slug, $label) = @$it;
            $h .= qq{<a href="$p$slug/">$label</a>\n};
        }
        $h .= qq{</div>\n</li>\n};
    }
    $h .= qq{</ul>};
    return $h;
}

sub header_html {
    my ($p, $cat) = @_;
    my $home = $p eq '' ? './' : $p;
    my $nav = nav_html($p, $cat);
    return <<HTML;
<header class="site">
<div class="header-inner">
<a class="brand" href="$home">
<img class="brand-mark" src="${p}assets/img/logo.png" alt="Logo da Escola de Pacientes DF">
<span class="brand-name"><strong>Escola de Pacientes</strong><span>Distrito Federal</span></span>
</a>
<input type="checkbox" id="nav-toggle" aria-hidden="true">
<label class="nav-toggle" for="nav-toggle" aria-label="Abrir menu"><span></span><span></span><span></span></label>
<nav class="main" aria-label="Navegação principal">
$nav
<div class="searchbox">
<input id="busca" type="search" placeholder="Buscar página…" aria-label="Buscar páginas do site" autocomplete="off" data-root="$p">
<div id="busca-resultados" class="search-results" role="listbox"></div>
</div>
</nav>
</div>
</header>
HTML
}

sub footer_html {
    my ($p) = @_;
    my $y = (localtime)[5] + 1900;
    return <<HTML;
<footer class="site">
<div class="wrap">
<div class="cols">
<div>
<h4>Escola de Pacientes DF</h4>
<p>Grupo de atividades acadêmicas coordenado pelo Prof. Dr. Estêvão Cubas Rolim, em atividade desde 2016 no Distrito Federal. Reúne formação em saúde, educação permanente, produção científica e integração ensino-serviço-comunidade, junto à Universidade de Brasília (UnB) e à Secretaria de Estado de Saúde do DF (SES-DF).</p>
</div>
<div>
<h4>Comece por aqui</h4>
<ul>
<li><a href="${p}para-pacientes/">Pacientes e comunidade</a></li>
<li><a href="${p}para-estudantes/">Estudantes</a></li>
<li><a href="${p}para-pesquisadores/">Pesquisadores</a></li>
<li><a href="${p}para-profissionais/">Profissionais e gestores</a></li>
<li><a href="${p}az/">Acervo completo (A–Z)</a></li>
</ul>
</div>
<div>
<h4>Ciência</h4>
<ul>
<li><a href="${p}publicacoes/">Publicações</a></li>
<li><a href="${p}congressos/">Congressos</a></li>
<li><a href="${p}ciencia-banco-de-citacoes/">Banco de citações</a></li>
<li><a href="${p}premios/">Prêmios</a></li>
</ul>
</div>
<div>
<h4>Recursos</h4>
<ul>
<li><a href="https://www.youtube.com/channel/UCMiHRdmhduWggK_c-UYEbLQ" target="_blank" rel="noopener">Canal no YouTube</a></li>
<li><a href="https://bit.ly/2BM7eVp" target="_blank" rel="noopener">Pasta de orientações</a></li>
<li><a href="https://bit.ly/30gwCfu" target="_blank" rel="noopener">Pasta de atendimento</a></li>
<li><a href="http://lattes.cnpq.br/3012202638503151" target="_blank" rel="noopener">Currículo Lattes</a></li>
<li><a href="https://orcid.org/0000-0001-7220-6276" target="_blank" rel="noopener">ORCID</a></li>
</ul>
</div>
</div>
<div class="fineprint">
<span>© 2016–$y Escola de Pacientes DF · Universidade de Brasília · SES-DF</span>
<span><a href="http://www.escoladepacientes.com" target="_blank" rel="noopener">Versão anterior do site</a></span>
</div>
</div>
</footer>
HTML
}

sub page_shell {
    my (%a) = @_;
    my $head_extra = $a{head_extra} // '';
    return <<HTML;
<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>$a{title}</title>
<meta name="description" content="$a{desc}">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Inter:ital,opsz,wght\@0,14..32,400..800;1,14..32,400..800&display=swap" rel="stylesheet">
<link rel="stylesheet" href="$a{p}assets/style.css">
<link rel="icon" href="$a{p}assets/img/logo.png">
$head_extra
</head>
<body>
$a{header}
$a{body}
$a{footer}
<script src="$a{p}assets/search-index.js" defer></script>
<script src="$a{p}assets/search.js" defer></script>
<script src="$a{p}assets/reveal.js" defer></script>
</body>
</html>
HTML
}

sub write_file {
    my ($path, $data) = @_;
    make_path(dirname($path));
    open my $fh, '>:encoding(UTF-8)', $path or die "$path: $!";
    print $fh $data; close $fh;
}

# ---------------- páginas de conteúdo ----------------
my $n = 0;
for my $path (sort keys %content) {
    my $depth = () = $path =~ m{/}g;
    my $p = '../' x ($depth + 1);
    my $title = title_of($path);
    my ($top) = split m{/}, $path;
    my $cat = $page{$top} ? $page{$top}{cat} : '';
    my $catlabel = $cat_label{$cat} // '';

    my $body_html = md_to_html($content{$path}, $p);

    # retrato do coordenador na página de apresentação
    if ($path eq 'dr-estevao-rolim') {
        $body_html = qq{<figure class="portrait"><img src="${p}assets/img/dr-estevao.jpg" alt="Foto do Prof. Dr. Estêvão Cubas Rolim"><figcaption>Prof. Dr. Estêvão Cubas Rolim</figcaption></figure>\n} . $body_html;
    }

    # lista de subpáginas ao final da página-mãe
    if ($children{$path}) {
        my @kids = @{ $children{$path} };
        my $count = scalar @kids;
        my $items = join "\n", map {
            my $t = esc(title_of($_));
            qq{<li data-t="\L$t\E"><a href="$p$_/">$t</a></li>}
        } sort { lc(title_of($a)) cmp lc(title_of($b)) } @kids;
        my $filter = '';
        my $script = '';
        if ($count > 30) {
            $filter = qq{<div class="filterbox"><input id="filtro" type="search" placeholder="Filtrar por autor, ano ou palavra-chave…" aria-label="Filtrar itens"><p class="filter-count" id="filtro-n">$count itens</p></div>};
            $script = <<'JS';
<script>
const inp = document.getElementById('filtro');
const itens = [...document.querySelectorAll('.childlist li')];
const nEl = document.getElementById('filtro-n');
inp.addEventListener('input', () => {
  const q = inp.value.trim().toLowerCase();
  let n = 0;
  itens.forEach(li => { const v = !q || li.dataset.t.includes(q); li.style.display = v ? '' : 'none'; if (v) n++; });
  nEl.textContent = n + (n === 1 ? ' item' : ' itens');
});
</script>
JS
        }
        $body_html .= qq{\n<h2 id="indice">Índice de páginas ($count)</h2>\n$filter\n<ul class="childlist">\n$items\n</ul>\n$script};
    }

    my $crumb = qq{<a href="$p">Início</a><span class="sep">›</span>};
    if ($depth > 0) {
        my $ptitle = esc(title_of($top));
        $crumb .= qq{<a href="$p$top/">$ptitle</a><span class="sep">›</span>};
    } elsif ($catlabel) {
        $crumb .= qq{<span>$catlabel</span><span class="sep">›</span>};
    }
    $crumb .= '<span>' . esc($title) . '</span>';

    my $body = <<HTML;
<div class="page-hero"><div class="wrap-narrow">
<nav class="breadcrumb" aria-label="Localização">$crumb</nav>
<h1>@{[esc($title)]}</h1>
</div></div>
<article class="content"><div class="wrap-narrow">
$body_html
</div></article>
HTML

    write_file("$OUT/$path/index.html", page_shell(
        title  => esc($title) . " — $SITE",
        desc   => esc($title) . " — material da $SITE: educação em saúde, educação permanente e formação em saúde.",
        p      => $p,
        header => header_html($p, $top),
        body   => $body,
        footer => footer_html($p),
    ));
    $n++;
}

# ---------------- índice de temas clínicos ----------------
{
    my $p = '../';
    my $groups_html = '';
    for my $g (@group_order) {
        my @slugs = grep { $page{$_}{cat} eq 'temas' && $page{$_}{group} eq $g } @order;
        next unless @slugs;
        my $items = join "\n", map { qq{<a href="$p$_/">$page{$_}{title}</a>} }
                    sort { lc($page{$a}{title}) cmp lc($page{$b}{title}) } @slugs;
        $groups_html .= qq{<div class="topic-group"><h2>$g</h2><div class="topic-grid">\n$items\n</div></div>\n};
    }
    my $body = <<HTML;
<div class="page-hero"><div class="wrap">
<nav class="breadcrumb" aria-label="Localização"><a href="$p">Início</a><span class="sep">›</span><span>Temas Clínicos</span></nav>
<h1>Temas Clínicos</h1>
</div></div>
<article class="content"><div class="wrap">
<p class="section-lead">Materiais de orientação, referência e educação em saúde organizados por área. Cada tema reúne impressos para pacientes, documentos técnicos e material de referência para estudo.</p>
$groups_html
</div></article>
HTML
    write_file("$OUT/temas/index.html", page_shell(
        title  => "Temas Clínicos — $SITE",
        desc   => "Índice de temas clínicos da $SITE, organizados por área.",
        p      => $p,
        header => header_html($p, 'temas'),
        body   => $body,
        footer => footer_html($p),
    ));
    $n++;
}

# ---------------- índice A–Z do acervo completo ----------------
{
    my $p = '../';
    # agrupa páginas de topo por inicial; subpáginas ficam com a mãe
    my %by_letter;
    for my $slug (grep { !m{/} } keys %content) {
        my $t = title_of($slug);
        my $letter = uc substr($t =~ s/^\s+//r, 0, 1);
        $letter = '#' unless $letter =~ /\p{L}/;
        $letter =~ tr/ÁÀÂÃÉÊÍÓÔÕÚÇ/AAAAEEIOOOUC/;
        push @{ $by_letter{$letter} }, [$slug, $t];
    }
    my $list = '';
    for my $l (sort keys %by_letter) {
        my @items = sort { lc($a->[1]) cmp lc($b->[1]) } @{ $by_letter{$l} };
        $list .= qq{<div class="topic-group"><h2 id="letra-$l">$l</h2><div class="topic-grid">\n};
        for my $it (@items) {
            my ($slug, $t) = @$it;
            my $extra = $children{$slug} ? ' <small>(' . scalar(@{ $children{$slug} }) . ' subpáginas)</small>' : '';
            $list .= qq{<a href="$p$slug/">@{[esc($t)]}$extra</a>\n};
        }
        $list .= qq{</div></div>\n};
    }
    my $letters_nav = join ' · ', map { qq{<a href="#letra-$_">$_</a>} } sort keys %by_letter;
    my $total = scalar(keys %content);
    my $body = <<HTML;
<div class="page-hero"><div class="wrap">
<nav class="breadcrumb" aria-label="Localização"><a href="$p">Início</a><span class="sep">›</span><span>Acervo</span><span class="sep">›</span><span>Índice A–Z</span></nav>
<h1>Acervo completo — Índice A–Z</h1>
</div></div>
<article class="content"><div class="wrap">
<p class="section-lead">Todas as $total páginas do acervo da Escola de Pacientes DF. Use a busca no topo do site ou navegue por letra: $letters_nav</p>
$list
</div></article>
HTML
    write_file("$OUT/az/index.html", page_shell(
        title  => "Índice A–Z — $SITE",
        desc   => "Índice completo de todas as páginas do acervo da $SITE.",
        p      => $p,
        header => header_html($p, 'az'),
        body   => $body,
        footer => footer_html($p),
    ));
    $n++;
}

# ---------------- landing page ----------------
{
    open my $fh, '<:encoding(UTF-8)', "$ROOT/landing.html" or die $!;
    local $/; my $tpl = <$fh>; close $fh;
    my $header = header_html('', 'inicio');
    my $footer = footer_html('');
    $tpl =~ s/\{\{HEADER\}\}/$header/;
    $tpl =~ s/\{\{FOOTER\}\}/$footer/;
    write_file("$OUT/index.html", $tpl);
    $n++;
}

# ---------------- assets ----------------
sub copy_raw {
    my ($src, $dst) = @_;
    make_path(dirname($dst));
    open my $in,  '<:raw', $src or die "$src: $!";
    open my $out, '>:raw', $dst or die "$dst: $!";
    local $/; print {$out} <$in>;
    close $in; close $out;
}
for my $a (glob "$ROOT/assets/*") {
    next if -d $a;
    my ($name) = $a =~ m{([^/\\]+)$};
    copy_raw($a, "$OUT/assets/$name");
}
for my $a (glob "$ROOT/assets/img/*") {
    my ($name) = $a =~ m{([^/\\]+)$};
    copy_raw($a, "$OUT/assets/img/$name");
}

# ---------------- índice de busca ----------------
{
    my @entries;
    push @entries, { t => 'Temas Clínicos (índice)', p => 'temas', c => 'Temas Clínicos' };
    for my $path (sort keys %content) {
        my ($top) = split m{/}, $path;
        my $cat = $page{$top} ? $cat_label{ $page{$top}{cat} } // '' : '';
        my $t = title_of($path);
        push @entries, { t => $t, p => $path, c => $cat };
    }
    my $json = join ",\n", map {
        my %e = %$_;
        for (values %e) { s/\\/\\\\/g; s/"/\\"/g; }
        qq{{"t":"$e{t}","p":"$e{p}","c":"$e{c}"}}
    } @entries;
    write_file("$OUT/assets/search-index.js", "window.SEARCH_INDEX = [\n$json\n];\n");
}

# ---------------- extras ----------------
write_file("$OUT/.nojekyll", '');
write_file("$OUT/404.html", page_shell(
    title  => "Página não encontrada — $SITE",
    desc   => "Página não encontrada.",
    p      => '/escola-de-pacientes-df/',
    header => header_html('/escola-de-pacientes-df/', ''),
    body   => qq{<div class="page-hero"><div class="wrap-narrow"><h1>Página não encontrada</h1></div></div><article class="content"><div class="wrap-narrow"><p>O endereço acessado não existe neste site. <a href="/escola-de-pacientes-df/">Voltar ao início</a>.</p></div></article>},
    footer => footer_html('/escola-de-pacientes-df/'),
));

print "OK: $n páginas geradas em docs/\n";

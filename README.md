# TBGWebCharts
TBGWebCharts for Delphi
<br>Componente para Criação de Gráficos e Dashboards.

Component for creating charts and dashboards.

<p align="center">
  <a href="https://t.me/+Rje_f2Bjh673Y5WJ">
    <img src="https://img.shields.io/badge/telegram-join%20channel-7289DA?style=flat-square">
  </a>
  <a href="https://www.youtube.com/@AcademiadoCodigo">
    <img src="https://img.shields.io/badge/youtube-join%20channel-7289DA?style=flat-square">
  </a>
</p>

O TBGWebCharts tem o objetivo de facilitar suas implementações de graficios, agilizando teu processo de desenvolvimento de software .

TBGWebCharts aims to facilitate your Charts graphics implementations, speeding up your software development process.

## ⚙️ Instalação/Installation
Instalação com boss [boss install](https://github.com/academiadocodigo/TBGWebCharts) comando:

Installation is done using the [boss install](https://github.com/academiadocodigo/TBGWebCharts) command:
``` sh
boss install abagrobrasil/TBGWebCharts
```

![image](https://github.com/grings/TBGWebCharts/assets/1357600/0e88cf11-b169-4c1f-a384-0888d9a0c3d4)

## 🔀 Qual backend de navegador usar? / Which browser backend to use?

O TBGWebCharts renderiza o dashboard sempre da mesma forma (`.WebBrowser(x).Generated`) — o que muda é qual controle você solta no formulário. Os três suportados hoje:

TBGWebCharts always renders the dashboard the same way (`.WebBrowser(x).Generated`) — what changes is which control you drop on the form. The three supported today:

| Backend | Distribuição / Distribution | Requisito de runtime / Runtime requirement | Plataformas / Platforms | Engine |
|---|---|---|---|---|
| **WebView2** (`TWebView2WindowParent`) | Só `WebView2Loader.dll` (~150 KB) junto do `.exe` | WebView2 Runtime — já vem no Windows 10 atualizado/11; instalador Evergreen p/ máquinas isoladas | Windows (VCL) | Chromium atual (evergreen, atualiza sozinho) |
| **CEF** (`TCEFWindowParent`, via CEF4Delphi) | Distribuição completa do Chromium Embedded (`libcef.dll`, locales, `.pak`) — centenas de MB | Nenhum — é autocontido, não depende do que está instalado no SO | Windows e, via FMX, macOS/Linux | Chromium fixo na versão que você empacota |
| **WebBrowser nativo** (`TWebBrowser`) | Nenhuma — o controle já existe no SO/VCL | Nenhum requisito extra no Windows (VCL); no FMX mobile usa a webview nativa da plataforma | Windows (VCL) e, via FMX, Android/iOS/macOS | **VCL: IE11/Trident** (legado, em fim de vida pela Microsoft); FMX mobile: engine nativa moderna da plataforma |

| Backend | Distribution | Runtime requirement | Platforms | Engine |
|---|---|---|---|---|
| **WebView2** (`TWebView2WindowParent`) | Just `WebView2Loader.dll` (~150 KB) next to the `.exe` | WebView2 Runtime — ships with updated Windows 10/11; Evergreen installer for isolated machines | Windows (VCL) | Current Chromium (evergreen, self-updating) |
| **CEF** (`TCEFWindowParent`, via CEF4Delphi) | Full Chromium Embedded distribution (`libcef.dll`, locales, `.pak` files) — hundreds of MB | None — fully self-contained, doesn't depend on what's installed on the OS | Windows and, via FMX, macOS/Linux | Chromium pinned to the version you ship |
| **Native WebBrowser** (`TWebBrowser`) | None — the control already exists in the OS/VCL | No extra requirement on Windows (VCL); FMX mobile uses the platform's native webview | Windows (VCL) and, via FMX, Android/iOS/macOS | **VCL: IE11/Trident** (legacy, being phased out by Microsoft); FMX mobile: modern native platform engine |

**Recomendação / Recommendation**: pra Windows puro, `WebView2` é hoje a opção mais leve e com engine mais atual, sem dependência de pacote externo — use CEF só se precisar fixar a versão exata do Chromium ou já estiver em FMX cross-platform desktop. Evite o `TWebBrowser` no VCL pra conteúdo novo — ele roda sobre IE11/Trident, sem suporte a JS/CSS modernos.

For pure Windows, `WebView2` is today the lightest option with the most current engine and no external package dependency — use CEF only if you need to pin an exact Chromium version or are already on FMX cross-platform desktop. Avoid `TWebBrowser` on VCL for new content — it runs on IE11/Trident, without modern JS/CSS support.

## 🌐 Usando com WebView2 (VCL) / Using with WebView2 (VCL)

Alternativa ao Chromium/CEF pra quem não quer depender de um pacote externo: o `TWebView2WindowParent` hospeda o Microsoft Edge WebView2 nativamente.

An alternative to Chromium/CEF for those who don't want an external package dependency: `TWebView2WindowParent` hosts Microsoft Edge WebView2 natively.

### 1. Pré-requisitos / Prerequisites

- **WebView2 Runtime**: já vem pré-instalado no Windows 10 (atualizado) e Windows 11. Se precisar garantir a presença em máquinas mais antigas/isoladas, baixe o instalador (Evergreen Bootstrapper ou Standalone) em [developer.microsoft.com/microsoft-edge/webview2](https://developer.microsoft.com/microsoft-edge/webview2#download-the-webview2-runtime).
- **WebView2Loader.dll**: **não está incluída neste repositório** (ela precisa acompanhar o executável final da sua aplicação, não a biblioteca — veja [Files to ship with the app](https://learn.microsoft.com/en-us/microsoft-edge/webview2/concepts/distribution#files-to-ship-with-the-app)). Pra obter o arquivo:
  1. Baixe o pacote NuGet `Microsoft.Web.WebView2` em [nuget.org/packages/Microsoft.Web.WebView2](https://www.nuget.org/packages/Microsoft.Web.WebView2) (um `.nupkg` é só um `.zip`, pode extrair com qualquer descompactador).
  2. Dentro do pacote, pegue o arquivo de `runtimes\win-x86\native\WebView2Loader.dll` (ou `win-x64`, conforme a plataforma do seu build).
  3. Copie esse `WebView2Loader.dll` pra mesma pasta do `.exe` da sua aplicação (não precisa ir pro repositório do componente).

### 2. Instalando o componente no formulário / Adding the component to a form

1. Com o pacote `TBGWebCharts` instalado na IDE (veja Instalação acima), arraste o `TWebView2WindowParent` (aba WebCharts da paleta) pro painel onde o dashboard vai aparecer.
2. **Defina `Align = alClient`** no `TWebView2WindowParent` (e confirme que todos os painéis pai, até o formulário, também estão com `Align` configurado corretamente) — sem isso o conteúdo fica preso num tamanho fixo e não acompanha o redimensionamento da janela.
3. Gere o dashboard **a partir do `OnShow` do formulário, não do `OnCreate`** — no `OnCreate` a janela ainda não tem seu tamanho final aplicado (principalmente com `WindowState = wsMaximized`), o que pode capturar um tamanho inicial errado pro WebView.

```pascal
procedure TForm1.FormShow(Sender: TObject);
begin
  WebCharts1
    .NewProject
      // ... monte o dashboard normalmente ...
    .WebBrowser(WebView2WindowParent1)
    .Generated;
end;
```

Um exemplo completo está em [Sample/VCL/WebView2_VCL](Sample/VCL/WebView2_VCL).

> **Nota histórica**: uma versão anterior deste README documentava aqui um bug de `.CDN(true)` no WebView2 (scripts externos supostamente ignorados). A causa raiz era outra: `TWebCharts.Create` não rodava pra componentes soltos no formulário, deixando `FModules` vazio — corrigido, não é mais necessário evitar `.CDN(true)`.
>
> **Historical note**: an earlier version of this README documented a `.CDN(true)` bug on WebView2 here (external scripts supposedly ignored). The real root cause was different: `TWebCharts.Create` never ran for form-dropped components, leaving `FModules` empty — fixed, no need to avoid `.CDN(true)` anymore.

## 👻 Ícones: Font Awesome ou Phosphor Icons / Icons: Font Awesome or Phosphor Icons

A fonte de ícone padrão é o Font Awesome (`fas fa-*`), mas qualquer componente que aceite `Icon(Value: String)` (ex.: `CardStyled`, `Progress`) recebe uma classe CSS crua — permitindo usar o **Phosphor Icons** (`ph ph-*`) como segunda opção, sem configuração extra:

The default icon source is Font Awesome (`fas fa-*`), but any component that accepts `Icon(Value: String)` (e.g. `CardStyled`, `Progress`) takes a raw CSS class — so **Phosphor Icons** (`ph ph-*`) works as a drop-in second option, no extra setup:

```pascal
'<i class="ph ph-heart"></i>'
'<i class="ph ph-house"></i>'
```

- **`.CDN(false)`** (padrão/default): o CSS + as fontes (`.woff2`/`.woff`, peso "regular", ~1200 ícones) vêm embutidos como `data:` URI no próprio HTML gerado — zero requisição externa, funciona offline. Isso é adicionado ao bundle "kitchen sink" que já existe pras outras libs; se o peso (~2MB a mais no offline) for um problema, use `.Modules([...])` (ver abaixo) pra incluir só o que sua tela usa.
- **`.CDN(true)`**: gera um `<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@phosphor-icons/web@2.1.1/src/regular/style.css">` apontando pro jsdelivr, sem embutir nada.

- **`.CDN(false)`** (default): CSS + fonts (`.woff2`/`.woff`, "regular" weight, ~1200 icons) are embedded as `data:` URIs directly in the generated HTML — zero external requests, works offline. This is added to the "kitchen sink" bundle that already exists for the other libs; if the extra weight (~2MB offline) is a problem, use `.Modules([...])` (see below) to include only what your screen actually uses.
- **`.CDN(true)`**: generates a `<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@phosphor-icons/web@2.1.1/src/regular/style.css">` pointing to jsdelivr instead of embedding anything.

### Reduzindo o bundle offline / Trimming the offline bundle

Por padrão, modo `.CDN(false)` embute TODAS as libs suportadas (Bootstrap, jQuery, Chart.js, DataTables, PivotTable+Plotly, Moment, D3, Quill, GMaps, Font Awesome, Phosphor Icons) em toda página gerada — retrocompatível, sem opt-in. Pra restringir a só o que sua tela usa, chame `.Modules([...])` com os itens de `TJSModule` (`Source/JSModules.pas`) que quiser:

By default, `.CDN(false)` mode embeds ALL supported libs (Bootstrap, jQuery, Chart.js, DataTables, PivotTable+Plotly, Moment, D3, Quill, GMaps, Font Awesome, Phosphor Icons) into every generated page — backwards-compatible, no opt-in required. To restrict it to only what your screen actually uses, call `.Modules([...])` with the `TJSModule` entries (`Source/JSModules.pas`) you need:

```pascal
WebCharts1
  .CDN(false)
  .Modules([jsBootstrap, jsJQuery, jsPopper, jsPhosphorIcons])
  .NewProject
    // ...
```

## 📊 Alinhamento de texto na Table / Table text alignment

Por padrão, a `Table` (DataTables) alinha número à direita automaticamente (campos `ftFloat`/`ftCurrency`/etc.) e deixa o resto sem classe — sem jeito de escolher manualmente. `TextAlignHead`/`TextAlignBody` (em `DataSet`) permitem forçar o alinhamento pra tabela inteira (cabeçalho e corpo), usando os valores do Bootstrap 5 via `TTextAlign` (`Source/Table/Table.Tipos.pas`, precisa de `uses Table.Tipos;`):

By default, `Table` (DataTables) auto-aligns numbers to the right (`ftFloat`/`ftCurrency`/etc. fields) and leaves everything else unstyled — no manual control. `TextAlignHead`/`TextAlignBody` (on `DataSet`) let you force alignment for the whole table (header and body), using Bootstrap 5's values via `TTextAlign` (`Source/Table/Table.Tipos.pas`, requires `uses Table.Tipos;`):

```pascal
uses Table.Tipos; // TTextAlign

WebCharts1
  .NewProject
    .Table
      .DataSet
        .DataSet(MyDataSet)
        .TextAlignHead(TTextAlign.taCenter)
        .TextAlignBody(TTextAlign.taCenter)
      .&End
    .&End
  .WebBrowser(WebView2WindowParent1)
  .Generated;
```

> `TTextAlign` é um *scoped enum* (`{$SCOPEDENUMS ON}`) de propósito — sem isso, `taCenter` vazaria pro namespace global (via `Interfaces.pas`, usado por tudo) e colidiria com o `TAlignment.taCenter` padrão da VCL. Por isso sempre `TTextAlign.taCenter`, nunca só `taCenter`.
>
> `TTextAlign` is a *scoped enum* (`{$SCOPEDENUMS ON}`) on purpose — without it, `taCenter` would leak into the global namespace (via `Interfaces.pas`, used by everything) and collide with VCL's own `TAlignment.taCenter`. Always `TTextAlign.taCenter`, never bare `taCenter`.

- `TTextAlign.taDefault` (padrão/default): comportamento de sempre — número alinha à direita sozinho, resto sem classe.
- `TTextAlign.taStart` / `.taCenter` / `.taEnd`: força `text-start`/`text-center`/`text-end` em **toda** célula (cabeçalho e/ou corpo, dependendo de qual dos dois métodos você chamar), sobrescrevendo o alinhamento automático de número.

`TTextAlign.taDefault` (default): usual behavior — numbers auto-align right, everything else unstyled.
`TTextAlign.taStart` / `.taCenter` / `.taEnd`: forces `text-start`/`text-center`/`text-end` on **every** cell (header and/or body, depending on which of the two methods you call), overriding the automatic number alignment.

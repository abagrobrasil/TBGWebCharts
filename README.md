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

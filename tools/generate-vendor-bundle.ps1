<#
.SYNOPSIS
  Baixa um asset de terceiro (JS/CSS) de uma URL fixada por versao e gera o
  fragmento Pascal (procedures + FPack.Add/FCode) no MESMO formato que os
  arquivos vendorizados deste componente ja usam (BootstrapJS.pas,
  PopperJS.pas, DataTableJS.pas, DataTableCss.pas, BootstrapCss.pas), pronto
  pra colar dentro do unit existente.

  NAO reescreve o unit inteiro (interface/class/CDN branch) - só produz:
    - lista de "procedure NomeN;" pra colar na declaracao da classe
    - o corpo de cada procedure
    - a lista de chamadas (NomeN;) pra colar dentro de PackJS/PackCSS

.PARAMETER Url
  URL do asset real (CDN), versao ja fixada na propria URL.

.PARAMETER Mode
  'Lines'   - conteudo é texto legivel com quebras de linha naturais
              (ex.: popper.js/bootstrap.js NAO minificados) - uma linha
              original = um FPack.Add(...). É o formato encontrado em
              PopperJS.pas (confirmado lendo o arquivo inteiro).
  'Chunked' - conteudo é minificado (poucas/nenhuma quebra de linha natural,
              ex.: bootstrap.min.css, datatables bs4/bs5 combo minificado) -
              fatiado artificialmente em pedacos de -ChunkSize caracteres.
              É o formato encontrado em DataTableCss.pas/DataTableJS.pas.
              IMPORTANTE: mesmo minificado, um chunk pode conter uma quebra
              de linha CRUA (ex.: banners tipo /*! ... */ que minificadores
              preservam verbatim, com \r\n internos) - Pascal NAO aceita
              quebra de linha dentro de uma string entre aspas simples, entao
              esse modo escapa qualquer \r/\n encontrado como concatenacao
              de codigo de caractere (#13/#10), quebrando a expressao em
              varios pedacos '...'+#13#10+'...' quando necessario.

.PARAMETER Base64
  Se setado, o conteudo é base64-codificado ANTES de fatiar (modo usado em
  BootstrapCss.pas/PhosphorIconsJS.pas, decodificado em runtime via
  IdCoderMIME). Só faz sentido junto com -Mode Chunked. Base64 nao tem \r\n
  cru (alfabeto so tem A-Z a-z 0-9 + /), entao esse problema nao se aplica
  aqui.

.PARAMETER Statement
  Template da linha gerada. Use '{0}' onde entra a string escapada.
  Ex.: "  FPack.Add('{0}');"  (padrao BootstrapJS.pas/PopperJS.pas)
       "  FCode := FCode + '{0}';"  (padrao DataTableCss.pas/DataTableJS.pas)

.PARAMETER ProcPrefix
  Prefixo do nome das procedures geradas (ex.: 'PopperJS' -> PopperJS_1,
  PopperJS_2, ...).

.PARAMETER LinesPerProc
  Quantas linhas geradas (FPack.Add/FCode) por procedure. Só serve pra
  organizar o arquivo em pedacos legiveis - Delphi nao tem limite pratico
  de tamanho de procedure que isso precise respeitar.

.PARAMETER WrapTag
  Opcional. Se setado (ex.: 'script' ou 'style'), adiciona uma primeira
  linha "<TAG>"+#13 e uma ultima linha "</TAG>"+#13 em volta do conteudo,
  igual PopperJS.pas faz com '<script>'+#13 / '</script>'+#13.

.PARAMETER OutFile
  Onde salvar o fragmento Pascal gerado (.txt ou .pas) - NUNCA sobrescreve
  o unit real, é sempre um arquivo novo/rascunho pra revisao manual antes
  de colar no lugar certo.

.EXAMPLE
  # Popper v2 (nao minificado, "Lines" mode) - reproduz o formato exato de
  # PopperJS.pas
  ./generate-vendor-bundle.ps1 `
    -Url "https://cdn.jsdelivr.net/npm/@popperjs/core@2.11.8/dist/umd/popper.js" `
    -Mode Lines -Statement "  FPack.Add('{0}');" -ProcPrefix "PopperJS" `
    -LinesPerProc 350 -WrapTag script `
    -OutFile "./tools/out/PopperJS.v2.fragment.pas"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)] [string]$Url,
    [Parameter(Mandatory = $true)] [ValidateSet('Lines', 'Chunked')] [string]$Mode,
    [switch]$Base64,
    [Parameter(Mandatory = $true)] [string]$Statement,
    [Parameter(Mandatory = $true)] [string]$ProcPrefix,
    [int]$LinesPerProc = 350,
    [int]$ChunkSize = 200,
    [string]$WrapTag = '',
    [Parameter(Mandatory = $true)] [string]$OutFile
)

$ErrorActionPreference = 'Stop'

function Escape-Pascal([string]$s) {
    return $s.Replace("'", "''")
}

# Converte um pedaco de texto CRU (pode conter \r/\n embutidos, ex.: banner
# de licenca preservado por um minificador) numa expressao Pascal completa e
# valida: '<texto1>'+#13#10+'<texto2>'+#10+... - cada quebra de linha crua
# vira uma concatenacao de codigo de caractere em vez de aparecer como uma
# quebra de linha real dentro da string (o que seria erro de compilacao).
# Limite REAL do compilador Delphi: um literal de string entre aspas simples
# aceita no maximo 255 caracteres (E2056 "String literals may have at most
# 255 elements") - concatenacao com + nao tem esse teto, so cada segmento
# entre aspas isoladamente. Usamos 250 (nao 255) por margem de seguranca.
$script:MaxLiteralLen = 250

# Quebra um texto JA ESCAPADO (aspas simples dobradas) em pedacos de no
# maximo MaxLiteralLen caracteres, sem nunca cortar no meio de um par ''
# (aspa escapada) - cortar ali criaria duas aspas soltas em segmentos
# diferentes em vez de uma aspa literal só.
function Split-EscapedForLiteralLimit([string]$escaped, [int]$maxLen) {
    $pieces = New-Object System.Collections.Generic.List[string]
    $i = 0
    $n = $escaped.Length
    if ($n -eq 0) { return $pieces }
    while ($i -lt $n) {
        $take = [Math]::Min($maxLen, $n - $i)
        $end = $i + $take
        if ($end -lt $n -and $escaped[$end - 1] -eq "'" -and $escaped[$end] -eq "'") {
            $take -= 1
        }
        $pieces.Add($escaped.Substring($i, $take))
        $i += $take
    }
    return $pieces
}

# Converte um pedaco de texto CRU (pode conter \r/\n embutidos, ex.: banner
# de licenca preservado por um minificador, E/OU ser mais longo que o limite
# de 255 chars por literal - ex.: uma linha de JS nao-minificado bem longa)
# numa expressao Pascal completa e valida:
# '<texto1>'+#13#10+'<texto2-parte1>'+'<texto2-parte2>'+... - cada quebra de
# linha crua vira concatenacao de codigo de caractere, e cada trecho de texto
# maior que o limite vira mais de um literal concatenado.
function Convert-PascalLiteral([string]$raw) {
    $parts = New-Object System.Collections.Generic.List[string]
    $textBuf = New-Object System.Text.StringBuilder
    $flushText = {
        if ($textBuf.Length -gt 0) {
            $escaped = Escape-Pascal $textBuf.ToString()
            foreach ($piece in (Split-EscapedForLiteralLimit $escaped $script:MaxLiteralLen)) {
                $parts.Add("'$piece'")
            }
            [void]$textBuf.Clear()
        }
    }
    $i = 0
    $n = $raw.Length
    while ($i -lt $n) {
        $c = $raw[$i]
        if ($c -eq "`r" -or $c -eq "`n") {
            & $flushText
            if ($c -eq "`r" -and ($i + 1) -lt $n -and $raw[$i + 1] -eq "`n") {
                $parts.Add('#13#10'); $i += 2
            }
            elseif ($c -eq "`r") { $parts.Add('#13'); $i += 1 }
            else { $parts.Add('#10'); $i += 1 }
            continue
        }
        [void]$textBuf.Append($c)
        $i += 1
    }
    & $flushText
    if ($parts.Count -eq 0) { return "''" }
    return ($parts -join '+')
}

# Inverso de Convert-PascalLiteral (e tambem entende uma string simples
# 'texto' sem nenhum #NN, usado por TODOS os modos na verificacao) - reparsa
# a expressao Pascal gerada e devolve o texto cru original (com \r/\n reais
# de volta), pra comparar contra o conteudo baixado.
function ConvertFrom-PascalLiteral([string]$expr) {
    $result = New-Object System.Text.StringBuilder
    $i = 0
    $n = $expr.Length
    while ($i -lt $n) {
        $c = $expr[$i]
        if ($c -eq "'") {
            $j = $i + 1
            while ($true) {
                if ($j -ge $n) { throw "String literal nao terminada na expressao: $expr" }
                if ($expr[$j] -eq "'") {
                    if (($j + 1) -lt $n -and $expr[$j + 1] -eq "'") {
                        [void]$result.Append("'")
                        $j += 2
                        continue
                    }
                    else { break }
                }
                [void]$result.Append($expr[$j])
                $j += 1
            }
            $i = $j + 1
        }
        elseif ($c -eq '#') {
            $j = $i + 1
            while ($j -lt $n -and [char]::IsDigit($expr[$j])) { $j += 1 }
            if ($j -eq $i + 1) { throw "Codigo de caractere invalido na expressao: $expr" }
            $code = [int]$expr.Substring($i + 1, $j - $i - 1)
            [void]$result.Append([char]$code)
            $i = $j
        }
        elseif ($c -eq '+') {
            $i += 1
        }
        else {
            throw "Caractere inesperado ('$c') fora de string/codigo na posicao $i da expressao: $expr"
        }
    }
    return $result.ToString()
}

Write-Host "Baixando $Url ..."
$raw = Invoke-WebRequest -Uri $Url -UseBasicParsing
$bytes = $raw.Content
if ($bytes -is [string]) {
    # Invoke-WebRequest as vezes ja devolve string decodificada; forca bytes UTF8 pra hash consistente.
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($bytes)
}
$originalHash = (Get-FileHash -InputStream ([System.IO.MemoryStream]::new($bytes)) -Algorithm SHA256).Hash
Write-Host "Baixado: $($bytes.Length) bytes. SHA256 original: $originalHash"

$text = [System.Text.Encoding]::UTF8.GetString($bytes)

$genLines = New-Object System.Collections.Generic.List[string]

# Prefixo/sufixo do template em volta do '{0}' literal - usado pras linhas
# de wrap (<script>/</script>) e pro modo Chunked-sem-base64 (que monta a
# propria expressao entre aspas na mao, por causa do Convert-PascalLiteral).
$templateMatch = [regex]::Match($Statement, "^(.*?)'\{0\}'(.*)$")
if (-not $templateMatch.Success) { throw 'Statement precisa ter exatamente um {0} entre aspas simples, ex.: "  FPack.Add(''{0}'');"' }
$stmtPrefix = $templateMatch.Groups[1].Value
$stmtSuffix = $templateMatch.Groups[2].Value

# IMPORTANTE: no modo Base64 (BootstrapCss.pas), a tag de wrap NAO é uma
# linha Pascal separada fora do base64 - ela é parte do PAYLOAD que é
# codificado (confirmado decodificando o inicio/fim do arquivo real:
# comeca com bytes "<style>\r\n...", termina com "...\r\n</style>\r\n",
# tudo dentro do mesmo blob base64). Só nos modos SEM base64 (Lines, ou
# Chunked sem -Base64) é que o wrap vira uma linha Pascal literal própria
# (padrao confirmado em PopperJS.pas / DataTableCss.pas: 'FCode := FCode +
# ''<script>''+#13;' como uma instrucao a parte).
$wrapInsidePayload = ($Base64 -and $WrapTag)

if ($WrapTag -and -not $wrapInsidePayload) {
    $genLines.Add("$stmtPrefix'<$WrapTag>'+#13$stmtSuffix")
}

if ($Mode -eq 'Lines') {
    if ($Base64) { throw "-Base64 nao se aplica a -Mode Lines (so faz sentido pra conteudo binario/minificado sem quebras naturais)." }
    $sourceLines = $text -split "`r`n|`n"
    foreach ($line in $sourceLines) {
        # NAO usa Escape-Pascal+Format direto aqui - uma linha de JS nao
        # minificado pode passar de 255 chars (ex.: um array literal grande
        # numa linha só), o que estoura o limite de literal do Delphi. Reusa
        # Convert-PascalLiteral (a mesma linha nunca tem \r/\n de verdade,
        # ja que foi obtida via -split, entao só a quebra por tamanho entra
        # em jogo aqui).
        $genLines.Add($stmtPrefix + (Convert-PascalLiteral $line) + $stmtSuffix)
    }
    $verifyOriginal = ($sourceLines -join "`r`n")
}
else {
    if ($Base64) {
        $payloadBytes = $bytes
        if ($wrapInsidePayload) {
            $payload = "<$WrapTag>`r`n" + $text + "`r`n</$WrapTag>`r`n"
            $payloadBytes = [System.Text.Encoding]::UTF8.GetBytes($payload)
        }
        $content = [Convert]::ToBase64String($payloadBytes)
        # a verificacao (mais abaixo) decodifica de volta e compara contra
        # os bytes originais SEM o wrap (o wrap é conteudo novo, adicionado
        # por nos, nao existe no arquivo baixado - so o CONTEUDO original
        # dentro do wrap precisa bater byte a byte).
        $verifyOriginal = $text
        for ($i = 0; $i -lt $content.Length; $i += $ChunkSize) {
            $len = [Math]::Min($ChunkSize, $content.Length - $i)
            $chunk = $content.Substring($i, $len)
            $genLines.Add([string]::Format($Statement, (Escape-Pascal $chunk)))
        }
    }
    else {
        $content = $text
        $verifyOriginal = $content
        for ($i = 0; $i -lt $content.Length; $i += $ChunkSize) {
            $len = [Math]::Min($ChunkSize, $content.Length - $i)
            $chunk = $content.Substring($i, $len)
            # NAO usa Escape-Pascal simples aqui - o chunk pode conter \r/\n
            # cru (banner de licenca preservado no CSS/JS minificado), que
            # precisa virar concatenacao de #13/#10 em vez de quebra de
            # linha real dentro da string (erro de compilacao em Pascal).
            $genLines.Add($stmtPrefix + (Convert-PascalLiteral $chunk) + $stmtSuffix)
        }
    }
}

if ($WrapTag -and -not $wrapInsidePayload) {
    $genLines.Add("$stmtPrefix'</$WrapTag>'+#13$stmtSuffix")
}

# --- Verificacao byte a byte ANTES de salvar qualquer coisa ---
# Reconstroi exatamente o que o Delphi vai produzir: reparsa a expressao
# Pascal de cada linha gerada (ConvertFrom-PascalLiteral entende tanto uma
# string simples 'texto' quanto 'texto1'+#13#10+'texto2') e junta (CRLF no
# modo Lines, direto no modo Chunked - TIdDecoderMIME.DecodeString é chamado
# por ITEM do FPack e os resultados sao concatenados, sem separador). Quando
# o wrap é uma linha Pascal separada (nao-base64), ela nao existe no arquivo
# original - excluida da comparacao.
$contentGenLines = $genLines
if ($WrapTag -and -not $wrapInsidePayload) { $contentGenLines = $genLines[1..($genLines.Count - 2)] }

# Extrai a EXPRESSAO entre o prefixo/sufixo exatos do template (sem assumir
# que logo depois do prefixo/antes do sufixo vem necessariamente uma aspa -
# um chunk que comeca ou termina bem na quebra de linha pode comecar/terminar
# com um #NN em vez de aspas).
function Extract-Expression([string]$line, [string]$prefix, [string]$suffix) {
    if (-not $line.StartsWith($prefix) -or -not $line.EndsWith($suffix)) {
        throw "Linha gerada nao bate com o prefixo/sufixo esperado do -Statement: $line"
    }
    return $line.Substring($prefix.Length, $line.Length - $prefix.Length - $suffix.Length)
}

if ($Mode -eq 'Lines') {
    $reconstructedLines = foreach ($l in $contentGenLines) {
        ConvertFrom-PascalLiteral (Extract-Expression $l $stmtPrefix $stmtSuffix)
    }
    $reconstructed = ($reconstructedLines -join "`r`n")
}
else {
    if ($Base64) {
        # simula exatamente o runtime: decodifica CADA chunk separadamente e
        # concatena os bytes decodificados (== TIdDecoderMIME.DecodeString
        # por FPack[I], somado em loop) - matematicamente equivalente a
        # decodificar tudo de uma vez, DESDE que cada chunk tenha tamanho
        # multiplo de 4 (garantido: base64 total sempre é multiplo de 4, e
        # ChunkSize=200 tambem é multiplo de 4, entao o resto tambem é).
        $decodedBytes = New-Object System.Collections.Generic.List[byte]
        foreach ($l in $contentGenLines) {
            $chunkB64 = ConvertFrom-PascalLiteral (Extract-Expression $l $stmtPrefix $stmtSuffix)
            $decodedBytes.AddRange([Convert]::FromBase64String($chunkB64))
        }
        $decodedText = [System.Text.Encoding]::UTF8.GetString($decodedBytes.ToArray())
        if ($wrapInsidePayload) {
            # tira o wrap que nós mesmos adicionamos antes de comparar contra o original (sem wrap)
            $openTag = "<$WrapTag>`r`n"
            $closeTag = "`r`n</$WrapTag>`r`n"
            if (-not ($decodedText.StartsWith($openTag) -and $decodedText.EndsWith($closeTag))) {
                throw "Wrap tag nao encontrado no conteudo decodificado - algo errado na montagem do payload."
            }
            $reconstructed = $decodedText.Substring($openTag.Length, $decodedText.Length - $openTag.Length - $closeTag.Length)
        }
        else {
            $reconstructed = $decodedText
        }
    }
    else {
        $reconstructedParts = foreach ($l in $contentGenLines) {
            ConvertFrom-PascalLiteral (Extract-Expression $l $stmtPrefix $stmtSuffix)
        }
        $reconstructed = ($reconstructedParts -join '')
    }
}

if ($reconstructed -ne $verifyOriginal) {
    Write-Host "MISMATCH nos primeiros 300 chars:" -ForegroundColor Red
    Write-Host "ORIGINAL : $($verifyOriginal.Substring(0, [Math]::Min(300,$verifyOriginal.Length)))"
    Write-Host "GERADO   : $($reconstructed.Substring(0, [Math]::Min(300,$reconstructed.Length)))"
    throw "Falha na verificacao round-trip: o conteudo reconstruido a partir das linhas Pascal geradas NAO bate com o original. Nada foi salvo."
}
Write-Host "Verificacao round-trip OK: reconstruido a partir das linhas Pascal == conteudo original, byte a byte." -ForegroundColor Green

# --- Monta o fragmento final (procedures + declaracoes + chamadas) ---
$procCount = [Math]::Ceiling($genLines.Count / [double]$LinesPerProc)
$sb = New-Object System.Text.StringBuilder
$sb.AppendLine("{ ==== Fragmento gerado por tools/generate-vendor-bundle.ps1 ==== }") | Out-Null
$sb.AppendLine("{ Fonte: $Url }") | Out-Null
$sb.AppendLine("{ SHA256 original: $originalHash }") | Out-Null
$sb.AppendLine("{ Gerado em: $(Get-Date -Format s) }") | Out-Null
$sb.AppendLine("") | Out-Null
$sb.AppendLine("{ --- Declaracoes pra colar na secao 'private'/'public' da classe --- }") | Out-Null
for ($p = 1; $p -le $procCount; $p++) {
    $sb.AppendLine("      procedure ${ProcPrefix}_$p;") | Out-Null
}
$sb.AppendLine("") | Out-Null
$sb.AppendLine("{ --- Corpos das procedures --- }") | Out-Null
for ($p = 1; $p -le $procCount; $p++) {
    $startIdx = ($p - 1) * $LinesPerProc
    $endIdx = [Math]::Min($startIdx + $LinesPerProc, $genLines.Count) - 1
    $sb.AppendLine("procedure T${ProcPrefix}.${ProcPrefix}_$p;") | Out-Null
    $sb.AppendLine("begin") | Out-Null
    for ($i = $startIdx; $i -le $endIdx; $i++) {
        $sb.AppendLine($genLines[$i]) | Out-Null
    }
    $sb.AppendLine("end;") | Out-Null
    $sb.AppendLine("") | Out-Null
}
$sb.AppendLine("{ --- Chamadas pra colar dentro de PackJS/PackCSS, no lugar das antigas --- }") | Out-Null
for ($p = 1; $p -le $procCount; $p++) {
    $sb.AppendLine("    ${ProcPrefix}_$p;") | Out-Null
}

$outDir = Split-Path -Parent $OutFile
if ($outDir -and -not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }
[System.IO.File]::WriteAllText($OutFile, $sb.ToString(), [System.Text.Encoding]::UTF8)
Write-Host "Fragmento salvo em: $OutFile ($procCount procedures, $($genLines.Count) linhas geradas)" -ForegroundColor Green

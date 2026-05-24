Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$saveDir = Join-Path $env:TEMP 'picosh'
$savePath = Join-Path $saveDir 'clip_latest.png'

New-Item -ItemType Directory -Force $saveDir | Out-Null

try {
    $img = [System.Windows.Forms.Clipboard]::GetImage()
    if ($img -ne $null) {
        $img.Save($savePath, [System.Drawing.Imaging.ImageFormat]::Png)
        Write-Output $savePath
        exit 0
    }

    # HTMLクリップボードから画像URL
    $html = [System.Windows.Forms.Clipboard]::GetText([System.Windows.Forms.TextDataFormat]::Html)
    if ($html) {
        $match = [regex]::Match($html, 'src=[\"'']([^\"'']+)[\"'']')
        if ($match.Success) {
            $url = $match.Groups[1].Value
            if ($url -match '^https?://') {
                Invoke-WebRequest -Uri $url -OutFile $savePath -UseBasicParsing
                Write-Output $savePath
                exit 0
            }
        }
    }
} catch {}

exit 1

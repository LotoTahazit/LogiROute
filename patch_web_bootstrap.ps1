$v = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
$root = $PSScriptRoot
$bootstrap = Join-Path $root 'build\web\flutter_bootstrap.js'
$c = Get-Content $bootstrap -Raw
$c = $c.Replace('mainJsPath":"main.dart.js"', "mainJsPath`":`"main.dart.js?v=$v`"")
Set-Content $bootstrap $c -NoNewline
Set-Content (Join-Path $root 'build\web\lr_epoch.txt') $v -NoNewline

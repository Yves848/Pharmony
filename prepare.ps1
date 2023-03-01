
[console]::Clear();
$width = $host.UI.RawUI.WindowSize.Width
Write-Host "".PadLeft($Width, "~")
Write-Host " Décompression des archives ....."
Expand-Archive -Path .\export_pharmonizer_712901_1673885076.zip . 
Expand-Archive -Path .\export_pharmonizer_extra_712901_1673885116.zip .
Write-Host " => 👍"




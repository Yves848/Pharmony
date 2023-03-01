function extractGalform {
  $mag = Import-Csv -Path .\magistrales.csv -Encoding utf8

  [System.Collections.Generic.List[String]]$galform = @()

  foreach ($prep in $mag ) {
    if ([string]::IsNullOrEmpty($prep.form)) {
      if (([string]$prep.name_nl).StartsWith("Magistraal:")) {
        $pattern = '(?<=\().+?(?=\))'
        [String[]]$match = ([regex]::Matches($prep.name_nl, $pattern).value) -split ' '
        if ($match.Length -eq 4) {
          $form = $match[0], $match[1] -join ' '
        }
        else {
          $form = $match[0]
        }
        if (-not [string]::IsNullOrEmpty($form)) {
          if ($galform.IndexOf($form) -eq -1) {
            $galform.Add($form)
          }
        }
      }
      if (([string]$prep.name_nl).StartsWith("Bereiding:")) {
        $pattern = "\:\s(.+)N"
        $text = $prep.name_nl
        $m = [regex]::Matches($text,$pattern)
        if ($m.success) {
          $form = ([string]$m.Groups[1].value).Trim()
          if ($galform.IndexOf($form) -eq -1) {
            $galform.Add($form)
          }
        }
      }
    }
  }

  return $galform
}

function getGalform {
  $mag = Import-Csv -Path .\magistrales.csv

  foreach ($prep in $mag ) {
    if (-not [string]::IsNullOrEmpty($prep.form)) {
      Write-Host ("{0} {1} {2}" -f ($prep.name_nl, $prep.form, $prep.id)) 
    }
  }
}

function getPharmonyGalForm() {
  $mag = Import-Csv -Path .\magistrales.csv
  $mag2 = $mag | Where-Object -Property form -NE ''
  $galform = @{}
  foreach ($prep in $mag2 ) {
    if (-not [string]::IsNullOrEmpty($prep.form)) {
      if (-not $galform.ContainsKey($prep.form)) {
        $galform.add($prep.form,$prep.name_nl)
      }
    }
  }
  return $galform
}

function copyPreparations {
  $prep =  Get-Content .\preparations.csv -Encoding utf8
  $mag = "magistrales.csv"
  if (Get-Item -Path $mag -ErrorAction Ignore) {
    Remove-Item $mag
  }
  $i = 0
  foreach ($line in $prep) {
    if ($i -gt 0) {
      $line = $line, "`n" -join "" 
      $line | Out-File -FilePath $mag -Encoding utf8 -Append -NoNewline
    }
    $i++
  }
  move-item -Path .\preparations.csv .\preparations.csv.original
}

function UpdatePreparaions {
  $mag = Import-Csv -Path .\magistrales.csv -Encoding utf8
  $galforms = @{
    "Gelules omhuld" = "2"
    "Gelules" = "1"
    "Gel" = "7"
    "Zalf" = "7"
    "Oplossing Inwendig" = "4"
    "Crème" = "7"
    "Oplossing Uitwendig" = "5"
    "Suppo volwassenen" = "8"
    "Pasta" = "7"
    "Poeders mengen" = "21"
    "Oogdruppels" = "12"
    "Ovule" = "10"
    "Poeders verdelen" = "21"
    "Suppo kind" = "9"
    "Oogzalf" = "23"
    "Mondspoeling" = "5"
    "Dermatologische gel" = "7"
    "Druppels uitwendig gebruik" = "5"
    "Orale gel" = "4"
    "Orale druppels" = "4"
  }
  $galconv = @{
    "8" = "8"
    "10" = "10"
    "30" = "16"
    "20" = "4"
    "15" = "22"
    "1" = "1"
    "40" = "25"
    "27" = "11"
    "90" = "14"
    "71" = "2"
    "21" = "5"
  }
  $i = 0
  while ($i -lt $mag.count) {
    $prep = $mag[$i]
    if ([string]::IsNullOrEmpty($prep.form)) {
      if (($prep.name_nl).StartsWith("Magistraal:")) {
        $pattern = '(?<=\().+?(?=\))'
        [String[]]$match = ([regex]::Matches($prep.name_nl, $pattern).value) -split ' '
        if ($match.Length -eq 4) {
          $form = $match[0], $match[1] -join ' '
        }
        else {
          $form = $match[0]
        }
        $gal = $galforms[$form]
        $mag[$i].form = $gal
        # Write-Host ("{0} {1} => " -f ($prep.id,$prep.name_nl)) -ForegroundColor Blue -NoNewline
        # Write-Host (" GalForm : {0}" -f ($gal)) -ForegroundColor Red 
      
      }
      if (($prep.name_nl).StartsWith("Bereiding:")) {
        $pattern = "\:\s(.+)N"
        $text = $prep.name_nl
        $m = [regex]::Matches($text,$pattern)
        if ($m.success) {
          $form = ([string]$m.Groups[1].value).Trim()
          $gal = $galforms[$form]
          # Write-Host ("{0} {1} => " -f ($prep.id,$prep.name_nl)) -ForegroundColor Green -NoNewline
        }
        $mag[$i].form = $gal
        #Write-Host (" GalForm : {0}" -f ($gal)) -ForegroundColor Red 
      
      }
      if ($prep.name_nl.StartsWith("HVK:") -or $prep.name_nl.StartsWith("EA:")) {
        # Write-Host ("{0} {1} => " -f ($prep.id,$prep.name_nl)) -ForegroundColor Yellow -NoNewline
        # Write-Host (" GalForm : {0}" -f ($gal)) -ForegroundColor Red 
        $gal = "14"
        $mag[$i].form = $gal
      }
     
    }
    else {
      $gal = $galconv[$prep.form]
      $mag[$i].form = $gal
    }
    $comment = ([string]$prep.content_comment).Replace("`n"," ")
    if ($comment.Length -gt 200) {
      $comment = $comment.Substring(0,200)
    }
    $mag[$i].content_comment = $comment
    $i++
  }
  $mag | Export-Csv -Path .\magistrales2.csv -Encoding utf8
}
Write-Host "".PadLeft($Width, "~")
Write-Host " Copie des fichiers ....."
copyPreparations
Write-Host " => 👍"
Write-Host "".PadLeft($Width, "~")
Write-Host " Mise à jour des formes galéniques ....."
UpdatePreparaions
Write-Host " => 👍"
$dummy = "2022-10-20 09:42:20 +0200,1.00,patients,BE,PHARMONY ONE,1.0"

function loadUnitRef {
  $refs = Import-Csv -Path .\unites_chimiques.csv -Encoding utf8
  $unitrefs = @{}
  foreach($ref in $refs) {
    $unitrefs.add($ref.cnk,$ref.CODEUNITEQUANTITE)
  }
  return $unitrefs
}

function Analyses2CSV {
  $analyse = "Analyses.csv"
  $raw = Get-Content -Raw .\component_analysis_record.json | ConvertFrom-Json
  # $file = $raw | Where-Object { ($null -ne $_.laboratory_id) -and ($null -ne $_.supplier_id)-and ($null -ne $_.unit)  } # Excluant les lignes SANS unités
  $file = $raw | Where-Object { ($null -ne $_.laboratory_id) -and ($null -ne $_.supplier_id) } # Incluant les lignes SANS unités
  $headers1 = $false
  $unitrefs = loadUnitRef
  [int]$id = 1
  if (Get-Item -Path $analyse -ErrorAction Ignore) {
    Remove-Item $analyse
  }
  $line = $dummy, "`n" -join ""
  $line | Out-File -FilePath $analyse -Encoding ascii -NoNewline

  foreach ($treatement in $file) {
    if ($headers1) {
      if ($unitrefs.containskey($treatement.code)) {
        $unit = $unitrefs[$treatement.code]
        $treatement.unit = [int]$unit
      }
     
    }
    if ($headers1 -eq $false) {
      $headers1 = $true
      $headers = ($treatement.psobject.properties | Where-Object { $_.name -ne "units_treatment_rows" } | Select-Object -Property Name).name -join "," 
      $headers = $headers, "`n" -join ""
      $headers | Out-File -FilePath $analyse -Append -Encoding ascii -NoNewline
    }
    if ($headers1) {
      $treatement.id = $id
    }
    [string]$line = ""
    foreach ($property in $treatement.psobject.properties) {
      if (-not [string]::IsNullOrEmpty($line)) {
        $line = $line, ",".trim() -join "" 
      }
      if ($property.typenameofvalue -eq "System.String") {
        $line = $line, "`"".trim(), ([string]$property.value).Trim(), "`"".trim() -join ""
      }
      else {
        $line = $line, ([string]$property.value).Trim() -join ""
      }  
    }
    $id++
    $line = $line, "`n" -join "" 
    $line | Out-File -FilePath $analyse -Append -Encoding ascii -NoNewline
  }
}

function schemaDetail (
  [pscustomobject]$unitrow,
  [string]$id,
  [string]$frequency,
  [string]$days
) {
  $detail = "schemadetail.csv"
  [string]$line = "`"".trim(), $id, "`"".trim() -join ""
  foreach ($property in $unitrow.psobject.properties ) {
    if (-not [string]::IsNullOrEmpty($line)) {
      $line = $line, ",".trim() -join "" 
    }
    if ($property.typenameofvalue -eq "System.String") {
      $line = $line, "`"".trim(), ([string]$property.value).Trim(), "`"".trim() -join ""
    }
    else {
      if ($property.Name -in ("t1", "t2", "t2b", "t2a", "t3", "t4", "t4a", "t4b", "t5", "t6", "t6a", "t6b", "t7", "t8")) {
        [decimal]$nb = 0.0 
        foreach ($value in  $property.value.psobject.properties) {
          if ($value.name -eq "whole") {
            $nb += [decimal]$value.value
          }
          if ($value.name -eq "half") {
            $nb += 0.5
          }
          if ($value.name -eq "quarter") {
            $nb += 0.25
          }
        
        }
        $line = $line, $nb -join "" 
      }
      else {
        $line = $line, ([string]$property.value).Trim() -join ""
      }
    } 
  }
  $line = $line, $frequency -join ","
  $line = $line, $days -join ","
  $line = $line, "`n" -join "" 
  $line | Out-File -FilePath $detail -Append -Encoding ascii -NoNewline
  # $unitrow
}

function schema2CSV {
  $traitement = "schema.csv"
  $headers1 = $false
  $headers2 = $false; 
  if (Get-Item -Path $traitement -ErrorAction Ignore) {
    Remove-Item $traitement
  }
  $detail = "schemadetail.csv"
  if (Get-Item -Path $detail -ErrorAction Ignore) {
    Remove-Item $detail
  }
  # $dummy | Out-File -FilePath $traitement -Encoding ascii
  # $dummy | Out-File -FilePath $detail -Encoding ascii

  $line = $dummy, "`n" -join ""
  $line | Out-File -FilePath $traitement -Encoding ascii -NoNewline
  $line | Out-File -FilePath $detail -Encoding ascii -NoNewline
  
  $treatements = Get-Content -Raw .\treatments.json | ConvertFrom-Json 
  foreach ($treatement in $treatements) {
    if ($headers1) {
      $freq = 0
      switch ($treatement.frequency_type) {
        1  { $freq = 2  }
        2  { $freq = 3  }
        3  { $freq = 4  }
        4  { $freq = 5  }
        5  { $freq = 1  }
        6  { $freq = 7  }
        7  { $freq = 2  }
        Default {$freq = 1}
      }
      $treatement.frequency_type = $freq
    }
    if ($headers1 -eq $false) {
      $headers1 = $true
      ($treatement.psobject.properties | Where-Object { $_.name -ne "units_treatment_rows" } | Select-Object -Property Name).name -join "," | Out-File -FilePath $traitement -Append -Encoding ascii
    }
    [string]$line = ""
    [string]$id = ""
    foreach ($property in $treatement.psobject.properties) {
      if ($property.name -eq "id") {
        $id = $property.value
      }
      if ($property.typenameofvalue -ne "System.Object[]") {
        if (-not [string]::IsNullOrEmpty($line)) {
          $line = $line, ",".trim() -join "" 
        }
        if ($property.typenameofvalue -eq "System.String") {
          $line = $line, "`"".trim(), ([string]$property.value).Trim().Replace("`n", ""), "`"".trim() -join ""
        }
        else {
          $line = $line, ([string]$property.value).Trim() -join ""
        } 
      }
      else {
        $unitrow = [pscustomobject]$property.value[0]
        if ($headers2 -eq $false) {
          $headers2 = $true
          $head = ($unitrow.psobject.properties | Select-Object -Property Name).name -join "," 
          $head = "schema_id,", $head -join ""
          $head = $head, "frequency_type," -join ","
          $head = $head, "days_interval" -join ""
          $head | Out-File -FilePath $detail -Append -Encoding ascii
        }
        schemaDetail -unitrow $unitrow -id $id -frequency $treatement.frequency_type -days $treatement.day_interval
      }
    }
    $line = $line, "`n" -join "" 
    $line | Out-File -FilePath $traitement -Append -Encoding ascii -NoNewline
  }
}

function PreparationSanitize {
  $mag = Get-Content .\magistrales2.csv -Encoding utf8
  $preparation = "preparations.csv"
  if (Get-Item -Path $preparation -ErrorAction Ignore) {
    Remove-Item $preparation
  }
  $line = $dummy, "`n" -join ""
  $line | Out-File -FilePath $preparation -Encoding utf8 -NoNewline

  foreach ($line in $mag) {
    if (-not $line.StartsWith("#")) {
      $line = $line.Replace("`n`r", "")
      $line = $line, "`n" -join "" 
      $line | Out-File -FilePath $preparation -Append -Encoding utf8 -NoNewline
    }
  }
}

Write-Host "".PadLeft($Width, "~")
Write-Host " Conversions des Fichier JSON -> CSV ....."
Write-Host "    Fiches d'analyse " -ForegroundColor Green
Analyses2CSV
Write-Host " => 👍"
Write-Host "    Schémas de médication " -ForegroundColor Green
schema2CSV
Write-Host " => 👍"
Write-Host "".PadLeft($Width, "~")
Write-Host "Assainissement des magistrales ....."
PreparationSanitize
Write-Host " => 👍"


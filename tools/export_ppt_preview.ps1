$pptPath = "C:\Users\KOSMO\Desktop\THE_NEXT_DEBUT.pptx"
$outDir = "C:\Users\KOSMO\Desktop\NEXTDEBUT\tmp\ppt_review"

New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$powerPoint = $null
$presentation = $null

try {
    $powerPoint = New-Object -ComObject PowerPoint.Application
    $powerPoint.Visible = $true
    $presentation = $powerPoint.Presentations.Open($pptPath, $false, $true, $false)
    $presentation.Export($outDir, "PNG", 1280, 720)
    Write-Output $outDir
}
finally {
    if ($presentation) { $presentation.Close() }
    if ($powerPoint) { $powerPoint.Quit() }
}

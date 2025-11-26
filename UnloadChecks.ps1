param(
    [Parameter(Mandatory=$false)]
    [string]$HandleFile,
    
    [Parameter(Mandatory=$false)]
    [string]$ModsFolder
)

Write-Host "[  JAVAW CHECK  ]" -ForegroundColor Cyan
Write-Host ""

if ([string]::IsNullOrWhiteSpace($ModsFolder)) {
    $ModsFolder = Read-Host "[INPUT] Enter the mods folder path"
}

if (-not (Test-Path $ModsFolder)) {
    Write-Host "ERROR: The specified folder does not exist: $ModsFolder" -ForegroundColor Red
    exit 1
}

$modsFolderInfo = Get-Item $ModsFolder
$modsLastModified = $modsFolderInfo.LastWriteTime

Write-Host "[MODS FOLDER]" -ForegroundColor Yellow
Write-Host "    Last modified: $($modsLastModified.ToString('dd/MM/yyyy HH:mm:ss'))" -ForegroundColor White
Write-Host " "

$javawProcesses = Get-Process -Name "javaw" -ErrorAction SilentlyContinue

if ($javawProcesses) {
    Write-Host "[ACTIVE JAVAW PROCESSES]" -ForegroundColor Yellow
    foreach ($proc in $javawProcesses) {
        Write-Host "    PID: $($proc.Id)" -ForegroundColor White
        Write-Host "    Started: $($proc.StartTime.ToString('dd/MM/yyyy HH:mm:ss'))" -ForegroundColor White
        
        $runTime = (Get-Date) - $proc.StartTime
        Write-Host "    Running for: $($runTime.Hours)h $($runTime.Minutes)m $($runTime.Seconds)s" -ForegroundColor White
        
        if ($modsLastModified -gt $proc.StartTime) {
            Write-Host "    Status: MODS MODIFIED AFTER PROCESS START" -ForegroundColor Red
            $timeDiff = $modsLastModified - $proc.StartTime
            Write-Host "    Difference: Mods modified $($timeDiff.Minutes)m $($timeDiff.Seconds)s after start" -ForegroundColor Yellow
        } else {
            Write-Host "    Status: No mods changes after start" -ForegroundColor Green
        }
    }
    Write-Host ""
} else {
    Write-Host "[JAVAW PROCESSES]" -ForegroundColor Yellow
    Write-Host "    No javaw.exe process active" -ForegroundColor Red
}

Write-Host ""

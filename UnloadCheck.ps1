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

$folderIdHex = (fsutil file queryfileid $ModsFolder) -replace '.*0x([0-9A-Fa-f]{32}).*','$1'
$folderId = [int64]("0x" + $folderIdHex.Substring(16))

Write-Host "[FOLDER ID]" -ForegroundColor Yellow
Write-Host "    File ID: $folderId" -ForegroundColor White
Write-Host " "

Write-Host "[USN JOURNAL ACTIVITY]" -ForegroundColor Yellow
$drive = Split-Path -Qualifier $ModsFolder
$usnOutput = fsutil usn readjournal $drive | Select-String -Pattern "FileId\s*:\s*0x[0-9a-fA-F]{16}$([Convert]::ToString($folderId, 16).PadLeft(16, '0'))" -Context 0,5

if ($usnOutput) {
    foreach ($entry in $usnOutput) {
        Write-Host $entry.Line -ForegroundColor White
        foreach ($contextLine in $entry.Context.PostContext) {
            Write-Host $contextLine -ForegroundColor Gray
        }
        Write-Host ""
    }
} else {
    Write-Host "    No recent activity found for this folder" -ForegroundColor Gray
}
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

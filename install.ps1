# GuDaStudio Subagents Installer for Windows
# https://github.com/GuDaStudio/subagents

param(
    [Alias("u")][switch]$User,
    [Alias("p")][switch]$Project,
    [Alias("t")][string]$Target,
    [Alias("a")][switch]$All,
    [Alias("s")][string[]]$Agent,
    [Alias("l")][switch]$List,
    [Alias("h")][switch]$Help
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$AvailableAgents = @("code-implementer", "code-reviewer", "plan-completion-checker", "project-planner")

function Write-ColorOutput {
    param(
        [string]$Text,
        [string]$Color = "White",
        [switch]$NoNewline
    )
    if ($NoNewline) {
        Write-Host $Text -ForegroundColor $Color -NoNewline
    } else {
        Write-Host $Text -ForegroundColor $Color
    }
}

function Show-Usage {
    Write-ColorOutput "GuDaStudio Subagents Installer" "Blue"
    Write-Host ""
    Write-Host "Usage: .\install.ps1 [OPTIONS]"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -User, -u              Install to user-level (~\.claude\agents\)"
    Write-Host "  -Project, -p           Install to project-level (.\.claude\agents\)"
    Write-Host "  -Target, -t <path>     Install to custom target path"
    Write-Host "  -All, -a               Install all available subagents"
    Write-Host "  -Agent, -s <name>      Install specific subagent (can be used multiple times)"
    Write-Host "  -List, -l              List available subagents"
    Write-Host "  -Help, -h              Show this help message"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\install.ps1 -User -All"
    Write-Host "  .\install.ps1 -Project -All"
    Write-Host "  .\install.ps1 -User -Agent project-planner"
    Write-Host "  .\install.ps1 -User -Agent project-planner -Agent code-implementer"
    Write-Host "  .\install.ps1 -Target C:\custom\path -All"
    Write-Host ""
    Write-Host "Available subagents:"
    foreach ($a in $AvailableAgents) {
        Write-Host "  - $a"
    }
}

function Show-AgentList {
    Write-ColorOutput "Available Subagents:" "Blue"
    Write-Host ""
    foreach ($a in $AvailableAgents) {
        $sourcePath = Join-Path $ScriptDir "agents\$a.md"
        if (Test-Path $sourcePath -PathType Leaf) {
            Write-Host "  " -NoNewline
            Write-ColorOutput "✓" "Green" -NoNewline
            Write-Host " $a"
        } else {
            Write-Host "  " -NoNewline
            Write-ColorOutput "✗" "Red" -NoNewline
            Write-Host " $a (not found in source)"
        }
    }
}

function Install-Agent {
    param([string]$AgentName, [string]$TargetDir)

    $sourceFile = Join-Path $ScriptDir "agents\$AgentName.md"
    $destFile = Join-Path $TargetDir "$AgentName.md"

    if (-not (Test-Path $sourceFile -PathType Leaf)) {
        Write-ColorOutput "Error: Subagent '$AgentName' not found in source directory" "Red"
        return $false
    }

    Write-Host "Installing " -NoNewline
    Write-ColorOutput "$AgentName" "Cyan" -NoNewline
    Write-Host " -> $destFile"

    if (-not (Test-Path $TargetDir)) {
        New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
    }

    if (Test-Path $destFile) {
        Write-ColorOutput "  Removing existing installation..." "Yellow"
        Remove-Item -Path $destFile -Force
    }

    Copy-Item -Path $sourceFile -Destination $destFile

    Write-ColorOutput "  ✓ Installed" "Green"
    return $true
}

if ($Help) {
    Show-Usage
    exit 0
}

if ($List) {
    Show-AgentList
    exit 0
}

$TargetPath = ""
if ($User) {
    $TargetPath = Join-Path $env:USERPROFILE ".claude\agents"
} elseif ($Project) {
    $TargetPath = ".\.claude\agents"
} elseif ($Target) {
    $TargetPath = $Target
}

if (-not $TargetPath) {
    Write-ColorOutput "Error: Please specify installation target (-User, -Project, or -Target)" "Red"
    Write-Host ""
    Show-Usage
    exit 1
}

if (-not $All -and (-not $Agent -or $Agent.Count -eq 0)) {
    Write-ColorOutput "Error: Please specify subagents to install (-All or -Agent)" "Red"
    Write-Host ""
    Show-Usage
    exit 1
}

$AgentsToInstall = @()
if ($All) {
    $AgentsToInstall = $AvailableAgents
} else {
    $AgentsToInstall = $Agent
}

foreach ($a in $AgentsToInstall) {
    if ($a -notin $AvailableAgents) {
        Write-ColorOutput "Error: Unknown subagent '$a'" "Red"
        Write-Host "Available subagents: $($AvailableAgents -join ', ')"
        exit 1
    }
}

Write-ColorOutput "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "Blue"
Write-ColorOutput "GuDaStudio Subagents Installer" "Blue"
Write-ColorOutput "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "Blue"
Write-Host ""
Write-Host "Target: " -NoNewline
Write-ColorOutput $TargetPath "Green"
Write-Host "Subagents: " -NoNewline
Write-ColorOutput ($AgentsToInstall -join ", ") "Green"
Write-Host ""

foreach ($a in $AgentsToInstall) {
    Install-Agent -AgentName $a -TargetDir $TargetPath
}

Write-Host ""
Write-ColorOutput "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "Green"
Write-ColorOutput "Installation complete!" "Green"
Write-ColorOutput "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "Green"

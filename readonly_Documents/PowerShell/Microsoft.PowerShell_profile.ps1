$env:POSH_GIT_ENABLED = $false

function prompt {
  if ("$(Get-Location)" -Ne $HOME) {
    $gitBranch = git rev-parse --abbrev-ref HEAD 2>$null
  }

  $dir = [System.IO.DirectoryInfo](Get-Location).Path

  if (-not $dir.Parent) {
    $p = $dir.FullName
  }
  elseif (-not $dir.Parent.Parent) {
    $p = $dir.Name
  }
  else {
    $p = "$($dir.Parent.Name)\$($dir.Name)"
  }

  $dt = [System.DateTime]::Now.ToString("HH:mm.ss");

  Write-Host " $dt" -NoNewline
  Write-Host " $p" -ForegroundColor Cyan -NoNewline
  if ($gitBranch) {
    Write-Host " $gitBranch" -ForegroundColor Red -NoNewline
  }
  " "
}

function gst { git status $args }
function gpl { git pull --rebase $args }
function gph { git push }
function gcmt { git commit -m "$args" }
function ssh { ssh.exe $args; $Host.UI.RawUI.WindowTitle = "PowerShell" }
function kn { k -n (Split-Path -leaf -path (Get-Location)) $args }


$null = Register-EngineEvent -SourceIdentifier 'PowerShell.OnIdle' -MaxTriggerCount 1 -Action {
  # Only enable prediction features when VT processing is available (interactive terminal)
  if (-not [Console]::IsOutputRedirected) {
      Set-PSReadLineOption -PredictionSource HistoryAndPlugin
      Set-PSReadLineOption -PredictionViewStyle ListView
  }

  # Shows navigable menu of all options when hitting Tab
  Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete

  # Exit with ctrl-d
  Set-PSReadlineKeyHandler -Key ctrl+d -Function ViExit

  # Autocompletion for arrow keys
  Set-PSReadlineKeyHandler -Key UpArrow -Function HistorySearchBackward
  Set-PSReadlineKeyHandler -Key DownArrow -Function HistorySearchForward

  Set-PSReadLineOption -HistorySearchCursorMovesToEnd

  If (Get-Command -Name "kubectl" -ErrorAction SilentlyContinue) {
    Invoke-Expression "$(kubectl completion powershell)"
    Register-ArgumentCompleter -CommandName 'k' -ScriptBlock $__kubectlCompleterBlock
    Register-ArgumentCompleter -CommandName 'kn' -ScriptBlock $__kubectlCompleterBlock
  }

  Invoke-Expression (& { (zoxide init powershell | Out-String) })
}

Set-Alias k kubectl
Set-Alias vsdev "$(& 'C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe' -latest -products * -property installationPath)\Common7\Tools\Launch-VsDevShell.ps1"

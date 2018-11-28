function Set-TokenColorConfiguration {
    # [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    param(
        [Parameter(Mandatory = $false)]
        $Theme,

        [Parameter(Mandatory = $false)]
        [switch] $Reset
    )

    $tokenColors = $Theme.tokens.readline
    $writeColors = $Theme.tokens.write

    if ($Reset) {
        $action = 'RESET'
        if (!$tokenColors) {
            # Set-PSReadlineOption -ResetTokenColors could be used, but is set to be deprecated in 2.0
            $tokenColors = [PSCustomObject]@{
                'foreground' = [PSCustomObject]@{
                    'Command'            = 'Yellow'
                    'Comment'            = 'DarkGreen'
                    'ContinuationPrompt' = 'Gray'
                    'DefaultToken'       = 'Gray'
                    'Emphasis'           = 'Cyan'
                    'Error'              = 'Red'
                    'Keyword'            = 'Green'
                    'Member'             = 'White'
                    'Number'             = 'White'
                    'Operator'           = 'DarkGray'
                    'Parameter'          = 'DarkGray'
                    'String'             = 'DarkCyan'
                    'Type'               = 'Gray'
                    'Variable'           = 'Green'
                }
                'background' = [PSCustomObject]@{
                    'Command'            = 'Black'
                    'Comment'            = 'Black'
                    'ContinuationPrompt' = 'Black'
                    'DefaultToken'       = 'Black'
                    'Emphasis'           = 'Black'
                    'Error'              = 'Black'
                    'Keyword'            = 'Black'
                    'Member'             = 'Black'
                    'Number'             = 'Black'
                    'Operator'           = 'Black'
                    'Parameter'          = 'Black'
                    'String'             = 'Black'
                    'Type'               = 'Black'
                    'Variable'           = 'Black'
                }
            }
        }

        if (!$writeColors) {
            $writeColors = [PSCustomObject]@{
                'foreground' = [PSCustomObject]@{
                    'Debug'    = 'Yellow'
                    'Error'    = 'Red'
                    'Progress' = 'Yellow'
                    'Verbose'  = 'Yellow'
                    'Warning'  = 'Yellow'
                }
                'background' = [PSCustomObject]@{
                    'Debug'    = 'Black'
                    'Error'    = 'Black'
                    'Progress' = 'Cyan'
                    'Verbose'  = 'Black'
                    'Warning'  = 'Black'
                }
            }
        }
    }
    else {
        # Reset tokens to the defaults before applying theme specific mappings
        # Attempts to resolve issue where DefaultToken is set incorrectly
        $action = 'SET'
        Set-TokenColorConfiguration -Reset
    }

    if (Get-Module PSReadLine) {
        Write-Debug "$action Readline Tokens"

        if ((Get-Module PSReadLine).Version.Major -ge 2) {
            # Breaking changes are coming in PSReadLine 2.0. Colors should be set via the -Colors parameter with a hashtable
            $foregroundColors = @{}
            foreach ($token in @('ContinuationPrompt', 'DefaultToken', 'Comment', 'Keyword', 'String', 'Operator', 'Variable', 'Command', 'Parameter', 'Type', 'Number', 'Member', 'Emphasis', 'Error')) {
                if ($tokenColors.foreground -and (Get-Member $token -InputObject ($tokenColors.foreground))) {
                    $foregroundColors[$token] = $($tokenColors.foreground.($token))
                }
            }

            $expression = "Set-PSReadlineOption -Colors `$foregroundColors"
            Write-Debug $expression
            Invoke-Expression $expression
        }
        else {
            foreach ($token in @('ContinuationPrompt', 'DefaultToken', 'Comment', 'Keyword', 'String', 'Operator', 'Variable', 'Command', 'Parameter', 'Type', 'Number', 'Member', 'Emphasis', 'Error')) {
                if ($tokenColors.foreground -and (Get-Member $token -InputObject ($tokenColors.foreground))) {
                    if ($token -in @('ContinuationPrompt', 'Emphasis', 'Error')) {
                        $expression = "Set-PSReadlineOption -$($token)ForegroundColor $($tokenColors.foreground.($token))"
                        Write-Debug $expression
                        Invoke-Expression $expression
                    }
                    elseif ($token -eq 'DefaultToken') {
                        Write-Debug "Set-PSReadlineOption 'None' -ForegroundColor $($tokenColors.foreground.($token))"
                        Set-PSReadlineOption 'None' -ForegroundColor $tokenColors.foreground.($token)
                    }
                    else {
                        Write-Debug "Set-PSReadlineOption $token -ForegroundColor $($tokenColors.foreground.($token))"
                        Set-PSReadlineOption $token -ForegroundColor $tokenColors.foreground.($token)
                    }
                }

                $background = $Theme.background
                if ($tokenColors.background -and (Get-Member $token -InputObject ($tokenColors.background))) {
                    $background = $tokenColors.background.($token)
                }
                if ($background) {
                    if ($token -in @('ContinuationPrompt', 'Emphasis', 'Error')) {
                        $expression = "Set-PSReadlineOption -$($token)BackgroundColor $background"
                        Write-Debug $expression
                        Invoke-Expression $expression
                    }
                    elseif ($token -eq 'DefaultToken') {
                        Write-Debug "Set-PSReadlineOption 'None' -BackgroundColor $background"
                        Set-PSReadlineOption 'None' -BackgroundColor $background
                    }
                    else {
                        Write-Debug "Set-PSReadlineOption $token -BackgroundColor $background"
                        Set-PSReadlineOption $token -BackgroundColor $background
                    }
                }
            }
        }
    }

    Write-Debug "$action Write Tokens"
    foreach ($token in @('Debug', 'Error', 'Progress', 'Verbose', 'Warning')) {
        if ($writeColors.foreground -and (Get-Member $token -InputObject ($writeColors.foreground))) {
            $expression = "`$Host.PrivateData.$($token)ForegroundColor = '$($writeColors.foreground.($token))'"
            Write-Debug $expression
            Invoke-Expression $expression
        }

        if ($token -eq 'Progress') {
            $background = 'Cyan'
        } else {
            $background = $Theme.background
        }

        if ($writeColors.background -and (Get-Member $token -InputObject ($writeColors.background))) {
            $background = $writeColors.background.($token)
        }

        if ($background) {
            $expression = "`$Host.PrivateData.$($token)BackgroundColor = '$background'"
            Write-Debug $expression
            Invoke-Expression $expression
        }
    }
}
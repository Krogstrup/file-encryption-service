@{
    # This is a console-only SendTo script. Write-Host is intentional:
    # it provides coloured feedback directly to the interactive user.
    ExcludeRules = @(
        'PSAvoidUsingWriteHost'
    )
}

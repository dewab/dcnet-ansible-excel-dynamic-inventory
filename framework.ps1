#!/usr/bin/env pwsh

if ($args -contains '--list') {
    $output = @{
        'all'   = @('server1.domain.com', 'server2.domain.com')
        'webservers' = @('server1.domain.com')
        '_meta' = @{
            'hostvars' = @{
                'server1.domain.com' = @{
                    myvar = 'metavariable'
                }
            }
        }
    }
    return $output | convertto-json -depth 99
}
elseif ($args -contains '--host') {
    $output = @{
        myvar2 = 'custom variable'
    }
    return $output | convertto-json
}
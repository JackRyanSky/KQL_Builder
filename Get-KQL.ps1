function Get-KQL{ #in 123 -> filter
    param( 
        [parameter()]
        [string] $IPorREGEXorMULTI = (read-host "`n1)IP Filter`n2)Regex Filter`n3)Multi Stage Query`n`n"),
        [parameter()]
        [string] $LineIPs,
        [parameter()]
        [string] $FileName,
        [parameter()]
        [switch] $s,
        [parameter()]
        [switch] $d
        )

    <# FUNCTION BLOCK BEGIN #>

    function recall(){ # in: function name out: call function again
    param(
        [parameter()]
        [string] $ret
        <#[parameter(ValueFromRemainingArguments = $true)]
        [string[]] $Arguements #>
        )
    $(&$ret <#$Arguements#>)
    }
    function srcdst { #in s/d -> query
    param(
        [parameter()]
        [string[]] $IPs,
        [parameter()]
        [switch] $source,
        [parameter()]
        [switch] $destination
        )

    if ($source -eq $false -and $destination -eq $false){
        switch ($(Read-Host "`n`n1) Source.ip`n2) Destination.ip`n3) Both`n`n")){
        "1" {
            $source = $true
            }
        "2" {
            $destination = $true
            }
        "3" {
            $source = $true
            $destination = $true
            }
        default {
            write-host "Chose an available option:"
            recall 'srcdst'
            break
            }
        }
    }
    foreach ($IP in $IPs){
        if ($source){
            $query = "$query$(lineCheck $IP "source.ip" )"
            }
        if ($destination){
            $query = "$query$(lineCheck $IP "destination.ip")"
            }
        }
    return $query
    }
    function FileLine { #in -> out | file or line -> array of IPs
    param(
        [parameter()]
        [string] $FileorLine = (read-host "`n1)File`n2)Line"),
        [parameter()]
        [string] $LineofIPs
        )

    if ($FileorLine -notmatch "[12]"){
        Write-host "Chose an available option:"
        Remove-Variable FileorLine
        recall "FileLine"
        break
    }
    switch ($FileorLine){
        "1" { #Get From File
            File $FileName #need to declare FileName at top of parent function when in big function
            }
        "2" { #Get From Line
            if ($LineofIPs -ne ""){
                return $(line $LineofIPs)
                }
            else {
                return $(line)
                }
            }
        }    
    }
    function File{ #in -> out | file name -> all IPs in an array
    param(
        [parameter()]
        [string] $FilesName = (read-host "What is the File name")
        )
        if ($FilesName -eq ""){
            recall "File"
            Break
            }
    $ArrayofIPs = @()
    foreach ( $line in $(get-content $FilesName)){
        if ($line -match "#"){
            continue
            }
        $ArrayofIPs += $line
        }
    return $ArrayofIPs
    }
    function Line{ #in -> out | line of IPs -> array of IPs
    Param(
        [parameter()]
        [string] $LineOfIPs = (read-host "What IPs are you selecting?`nEach block of IPs must be semicolon deliminated`nAccepts CIDR Notation, comma deliminated and single IPs Example:`n192.168.0.1/24;10.0.0.0,10.255.255.255;8.8.8.8`n`n")
        )
    if ($true){
        return @($LineOfIPs.Split(";"))
        }
    }
    function lineCheck(){ # in: line and field     out: range function
    param(
        [parameter(Mandatory, Helpmessage = 'No Line provided')]
        [string] $line,
        [parameter(Mandatory, Helpmessage = 'source.ip | destination.ip')]
        [string] $field
        )
    if ($line -notmatch "^((25[0-5]|(2[0-4]|1\d|[1-9]|)\d)\.?\b){4}" -or $field -notmatch "^(source\.ip|destination\.ip)$"){
        Write-Error "IP formatted incorrectly or no field selected. Please Try again"
        recall "lineCheck"
        }
    if ( $line -match ","){
        $a = $line.Split(",")
        return $(rangeFunction $field $a[0] $a[1])
        }
    elseif( $line -match "/"){
        $netAndBroad = $(CIDRtoRange $line)
        return $(rangeFunction $field $netAndBroad[0] $netAndBroad[1])
        }
    else{
        return $(matchFunction $field $line)
        }
    }
    function CIDRtoRange { # in: cidr IP out: network and broadcast address
    param(
        [Parameter(ValueFromPipeline, Mandatory, HelpMessage = 'Please enter subnet in CIDR notation (#.#.#.#/#)')]
        [string] $CidrIP
        )
    if ( $cidrIP -notmatch "^((25[0-5]|(2[0-4]|1\d|[1-9]|)\d)\.?\b){4}[\/][\d][\d]?$"){
        write-error "CIDR notation not inputted correctly. Please try again"
        recall "CIDRtoRange"
        break
        }
    $IP, $CIDR = $CidrIP.Split("/")
    $binOctArr = $IP.Split(".")
    $i = 0
    foreach ($oct in $binOctArr ){
        $binoct = [convert]::tostring("$oct",2) #making octet binary
        $binOctArr[$i] = ($binoct.padleft(8, '0')) #ensuring 8 numbers in each octet
        $i++
        } #foreach could be avoided with this command: [convert]::tostring(([ipaddress][string]([ipaddress]"$IP").Address).Address,2) although I don't understand it so I'm not using it
    $binIP = $binOctArr -join '' # Create binary IP
    $HostBits = 32 - $CIDR
    $subnetMask = ('1' * ($CIDR) + '0' * ($HostBits)) #creating subnetmask
    $wildcardMask = ('0' * ($CIDR) + '1' * ($HostBits)) #creating wildcard mask
    $networkBinIP = [convert]::tostring([convert]::toint32($binIP,2) -band [convert]::ToInt32($subnetMask,2),2)  #bitwise and between the IP address and the subnetmask = network address
    $broadcastBinIP = [convert]::tostring([convert]::toint32($binIP,2) -bor [convert]::ToInt32($wildcardMask,2),2) #bitwise or between the IP address and the wildcard mask = broadcast IP address
    $networkIP = ([IPaddress]"$([convert]::toint64("$networkBinIP",2))").IPAddressToString #converting from a binary IP to a '.' deliminated IP. Without ".IPAddressToString" it's an object and I only want the IP
    $broadcastIP = ([IPaddress]"$([convert]::toint64("$broadcastBinIP",2))").IPAddressToString # converting from binary IP to '.' deliminated IP.
    return @($networkIP, $broadcastIP) #return an array containing the network and broadcast IP's
    }
    function matchFunction(){
    [cmdletbinding()]
    param(
        [parameter()]
        [string] $field = $(read-host "What is the field name?"),
        [parameter()]
        [string] $value = $(read-host "What is the exact phrase that you are trying to match?")
        )
    $query = ("{`"match_phrase`":{`"$field`":`"$value`"}},")
    return $query
    }
    function rangeFunction(){
    param(
        [parameter(Mandatory)]
        [string] $srcdst,
        [parameter(Mandatory)]
        [string] $start,
        [parameter(Mandatory)]
        [string] $end
        )
    if ($srcdst -notmatch "^(source\.ip|destination\.ip)$" -or $start -notmatch "((25[0-5]|(2[0-4]|1\d|[1-9]|)\d)\.?\b){4}" -or $end -notmatch "((25[0-5]|(2[0-4]|1\d|[1-9]|)\d)\.?\b){4}"){
        Write-Error "Something went wrong"
        recall "rangeFunction"
        break
        }
    $query = "{`"range`":{`"$srcdst`":{`"lt`":`"$end`",`"gte`":`"$start`"}}}," # use .TrimEnd(",") method if you only need one
    return $query
    }

    <# uneeded contains functions that were able to be variables
    function addAND(){
    return "{`"bool`":{`"must`":["
    }
    function addOR(){
    "{`"bool`":{`"should`":["
    }
    function endANDOR(){
    return "]}}"
    }
    #> #uneeded contains functions that were able to be variables

    <# FUNCTION BLOCK END #>
    <# ------------------ #>
    <# VARIABLE BLOCK BEGIN #>

    $addAND = "{`"bool`":{`"must`":["
    $addOR = "{`"bool`":{`"should`":["
    $endANDOR = "]}}"

    <# VARIABLE BLOCK BEGIN #>

    if ($IPorREGEXorMULTI -notmatch "[123]"){
        Write-host "Chose an available option:"
        Remove-Variable IPorREGEXorMULTI
        recall "Get-KQL"
        break
        }
    switch ($IPorREGEXorMULTI){
        "1" { #IP Filter
            $query = "$addOR"
            if ($FileName -ne ""){
                $IPArray = $(FileLine -FileorLine "1" "$FileName")
                }
            elseif ($LineIPs -ne ""){
                $IPArray = $(FileLine -FileorLine "2" "$LineIPs")
                }
            else{
                $IPArray = $(FileLine)
                }
            if ($s){
                $query = "$query$(srcdst $IPArray -source)"
                }
            if ($d){
                $query = "$query$(srcdst $IPArray -destination)"
                }
            if (-not $s -and -not $d){
                $query = "$query$(srcdst $IPArray)"
                }
            $query = $query.TrimEnd(",")
            $query = "$query$endANDOR"
            write-host $query
            }
        "2" { #Regex Filter not finished
           
            write-host "in Regex filter"
           
            }
        "3" { #Multi-Stage not finished
           
            write-host "in multi stage"

            }
        default {
            write-error "How did you get here?"
            break
            }
        }
    }

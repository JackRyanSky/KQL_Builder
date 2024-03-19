function main {
    $sourceField = "source.ip"
    $destinationField = "destination.ip"
    while ($true) {
        $query = ""
        $userinput = (read-host -Prompt "Welcome to the EPIC DSL Builder`nPick an Option below:`n`n1) REGEX`n2) LIST OF VALUES`n3) IP list from file`n4) EXIT`n`n") #welcome terminal -> $userinput
        if ($userinput -eq "1") {
            write-host "you chose option 1 REGEX`n" 
            $field = (read-host "What is the field name?")
            $regex = (read-host "Write your regex")
            return $(regexFunction $field $regex).TrimEnd(",") #todo: ensure this works
            }
 
        elseif ($userinput -eq "2") {
            write-host "you chose option 2 LIST OF VALUES`n"
            $ipsorregex = (read-host "`n`nHow do you want to build this?`n1) With a list of IPs`n2) With a list of regex`n3) Filters`n")
 
            if ($ipsorregex -eq "1"){
                write-host "`nYou chose option 1, a list of IPs. To do a range of IPs, Accepts CIDR Notation, comma deliminated and single IPs Example:`n192.168.0.1/24`n10.0.0.0,10.255.255.255`n8.8.8.8`n`n"
                $query = "$(addOR)"
                :labelA while ($true) {
                    $srcdstboth = (read-host "`nWhich field do you want to filter for?`n`n1) Source`n2) Destination`n3) Source and Destination`n4) STOP")
                    if ($srcdstboth -eq "4"){
                        write-host "Stopping and returning filter"
                        break
                        }
                    $ip = (read-host "STOP or write IP here")
                    if ($srcdstboth -eq "1" -or $srcdstboth -eq "3"){
                        #write-host "`nYou chose option 1, Source (or both)"
                        $query = "$query$(lineCheck $IP $sourcefield)"
                    }
                    if ($srcdstboth -eq "2" -or $srcdstboth -eq "3"){
                        #write-host "`nYou chose option 2, Destination (or both)"
                        $query = "$query$(lineCheck $IP $destinationField)"
                        }
                    else {
                        write-host "`nUnexpected input found, sanitizing IP and continuing"
                        $ip = ""
                        continue :labelA
                        }
                    }
                $query = $query.TrimEnd(",")
                $query = "$query$(endANDOR)"
                return $query
                }
            elseif ($ipsorregex -eq "2"){
                write-host "Work in progress, not finished" #TODO: this
                }
            elseif ($ipsorregex -eq "3") {
                $andor = (write-host "`nYou chose option 3, Filters`n`nWhat do you want your base filter to be?`n1) AND`n2) OR")
                if ($andor -eq "1"){
                    $query = $(addAND)
                    }
                elseif ($andor -eq "2"){
                    $query = $(addOR)
                    }
                else {
                    write-host "`nUnexpected input found, please select a given option"
                    }
                while ($true){
                    $filter = $(read-host "`n`nWhich filter would you like to add?`n1) Regex`n2) Exact String Match`n3) Range of IPs`n4) STOP`n`n")
                    if ($filter -eq "1"){
                        write-host "Regex"
                        }
                    elseif ($filter -eq "2"){
                        write-host "Exact String Match"
                        }
                    elseif ($filter -eq "3"){
                        write-host "Range of IPs"
                        }
                    elseif ($filter -eq "4"){
                        write-host "STOP"
                        return 0
                        }
                    else{
                        write-host "input validation"
                        }
                    }
                }
 
            else {
                write-host "`nUnexpected input found, please select a given option"
                }
            }
        elseif ($userinput -eq "3") {
            $srcdstboth = (read-host "You chose option 3, Large IP list.`nEnsure IPs are in .\IOC_IPs.txt`nAccepts CIDR Notation, comma deliminated and single IPs Example:`n192.168.0.1/24`n10.0.0.0,10.255.255.255`n8.8.8.8`n1) Source`n2) Destination`n3) Both`n`n")
            $query = addOR
            if ($srcdstboth -eq "1" -or $srcdstboth -eq "3"){
                write-host "`nYou chose option 1, Source (or both)"
                foreach ( $line in $(get-content .\IOC_IPs.txt)){
                    if ($line -match "#"){
                        continue
                        }
                    $query = "$query$(lineCheck $line $sourceField)"
                    }
                }
            if ($srcdstboth -eq "2" -or $srcdstboth -eq "3"){
                write-host "`nYou chose option 2, Destination (or both)"
                foreach ( $line in $(get-content .\IOC_IPs.txt)){
                    if ($line -match "#"){
                        continue
                        }
                    $query = "$query$(lineCheck $line $destinationField)"
                    }
                }
            else {
                write-host "`nUnexpected input found, please select a given option"
                }
            $query = $query.trimend(",")
            $query = "$query$(endANDOR)"
            return $query
            }
        elseif ($userinput -eq "4") {
            write-host "`nExiting"
            return 0
            }
        else {
            write-host "`nUnexpected input found, please select a given option"
            continue
            }
        }
    }
 
function CIDRtoRange {
    param(
        [Parameter(ValueFromPipeline, Mandatory, HelpMessage = 'Please enter subnet in CIDR notation (#.#.#.#/#)')][string] $CidrIP
        )
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
 
 
function lineCheck($line, $field){
    if ( $line -match ","){
        $a = $line.Split(",")
        return $(rangeFunction $field $a[0] $a[1])
        }
    elseif( $line -match "/"){
        $netAndBroad = $(CIDRtoRange $line)
        return $(rangeFunction $field $netAndBroad[0] $netAndBroad[1])
        }
    else{
        return $(matchIPFunction $field $line)
        }
    }
 
function regexFunction($field, $regex){
    $query = "{`"regexp`":{`"$field`":`"$regex`"}}," # use .TrimEnd(",") method if you only need one
    return $query
    }
 
 
function rangeFunction($srcdst, $start, $end){
    $query = "{`"range`":{`"$srcdst`":{`"lt`":`"$end`",`"gte`":`"$start`"}}}," # use .TrimEnd(",") method if you only need one
    return $query
    }
 
function matchFunction(){
    $field = (read-host "What is the field name?")
    $phrase = (read-host "What is the exact phrase that you are trying to match?")
    $query = ("{`"match_phrase`":{`"$field`":`"$phrase`"}},")
    return $query
    }
 
function matchIPFunction ($fieldName, $valueName){
    $query = "{`"match_phrase`":{`"$fieldName`":`"$valueName`"}},"
    return $query
    }
 
function addAND(){
    return "{`"bool`":{`"must`":["
    }
 
function addOR(){
    "{`"bool`":{`"should`":["
    }
 
function endANDOR(){
    return "]}}"
    }

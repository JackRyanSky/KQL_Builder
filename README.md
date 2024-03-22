# KQL_Builder
Build Kibana Query language queries  
Work in progress. 
There are two versions, Get-KQL is the most up to date and the one I will be continuing with. It can run as a single command, and it will prompt for the information it needs, or you can run it with optional switches. When I have time i will be creating a -help menu as that is not yet one of the options.  

Main functionality is to take a cutsheet of IP's and turn that into a KQL query.  
To use: download ps1 and call main in the terminal. IOC_IPs.txt is only necessary for a list of IPs.  
# REGEX
Regex in kibana is different  
Link for kibana regex: https://www.elastic.co/guide/en/elasticsearch/reference/current/regexp-syntax.html
# IP Lists
For File:  
Place IP's to be searched into file. If you want to skip over a line, Put "#' anywhere in the line  
Format:    
CIDR Notation  
comma deliminated  
single IP  
Ex.  
192.168.0.1/24   
10.0.0.5,10.0.0.10  
8.8.8.8  
For a string in terminal or when prompting:  
CIDR Notation;comma,deliminated;singleIP  
Ex.  
192.168.0.1/24;10.0.0.5,10.0.0.10;8.8.8.8  
# TODO  
[] Help menu  
[] Fix functions breaking if you don't supply correct values  
[] Input validation / stress test  
[] regex functionality and possibly some default regex queries  
Made by: Jack Ryan  

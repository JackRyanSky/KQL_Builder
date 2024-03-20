# KQL_Builder
Build Kibana Query language queries  
Work in progress. Main functionality is to take a cutsheet of IP's and turn that into a KQL query.
To use: download ps1 and call main in the terminal. IOC_IPs.txt is only necessary for a list of IPs.
# REGEX
Regex in kibana is different  
Link for kibana regex: https://www.elastic.co/guide/en/elasticsearch/reference/current/regexp-syntax.html
# IP Lists
Place IP's to be searched into ./IOC_IPs.txt
Format:  
CIDR Notation  
comma deliminated  
single IP  
Ex.  
192.168.0.1/24   
10.0.0.5,10.0.0.10  
8.8.8.8  
# TODO
[ ] Saved regex queries  
[ ] Multi-Level queries  
[ ] Anything else (idk)  
[ ] GUI Support??  

Made by: Jack Ryan

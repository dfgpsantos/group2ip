# group2ip


This tool helps NSX users that migrated from NSX-V to T using the migration coordinator and got multiple groups with the auto-generated display name "ipaddress-group-xxxxxxx".
The tool will look for DFW rules with those ip sets groups and replace them by IP addresses.
It supports single IP addresses and subnets in the CIDR notation.
When running the script it's possible to update only a single policy at a time or all DFW policies at once.

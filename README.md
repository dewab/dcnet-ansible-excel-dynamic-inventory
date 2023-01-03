# DCNET-ANSIBLE-EXCEL-DYNAMIC-INVENTORY
## Synopsis
Use an Excel (.xlsx) file as a dynamic inventory source for Ansible.

## Description
Uses PowerShell and the Import-Excel module to create Ansible dynamic inventories (JSON format).

$filename specifies the XLSX file to use as the inventory source.
$worksheet specifies which worksheet to use.
$HostnameCol specifies which column in the worksheet should map to the Ansible hostname.
$GroupByCol specifies a column for which to group ansible hosts by (optional).

## Author
Daniel Whicker ( Daniel.Whicker@computacenter.com )

## Dependencies
- PowerShell (Tested with PowerShell 7.3.1 on MacOS 13.1)
- ImportExcel Modules (https://github.com/dfinke/ImportExcel)

## Notes
A single (specified) worksheet with columns identifying HostVars and rows identifying individual hosts is assumed.

## Link
https://github.com/dewab/dcnet-ansible-excel-dynamic-inventory

## Example
Without ansible, listing all hosts:
```
% ./excel_inv.ps1 --list
{
  "CentOS7": [
    "host01",
    "host02",
    ...
```

Without ansible, listing specific hosts vars:
```
% ./excel_inv.ps1 --host host01
{
  "OS": "CentOS7",
  "IP1": 0.0,
  ...
```

Using with ansible:
```
% ansible --list-hosts -i ./excel_inv.ps1 all
  hosts (127):
    host01
    host02
    ...
```

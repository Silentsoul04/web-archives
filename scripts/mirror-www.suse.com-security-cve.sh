#!/bin/bash

wget -x https://www.suse.com/security/cve/

grep "^<a href=\"CVE-" www.suse.com/security/cve/index.html  | cut -d"\"" -f2 | sed 's/^/https:\/\/www.suse.com\/security\/cve\//' > www.suse.com/security/cve/urls-listed.txt

ls  www.suse.com/security/cve/CVE*.html | sed 's/^/https:\/\//' > www.suse.com/security/cve/urls-got.txt

cat www.suse.com/security/cve/urls-got.txt www.suse.com/security/cve/urls-listed.txt | sort | uniq -u > www.suse.com/security/cve/urls.txt

wget -x -i www.suse.com/security/cve/urls.txt

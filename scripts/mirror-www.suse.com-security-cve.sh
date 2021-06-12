#!/bin/bash

wget -x https://www.suse.com/security/cve/

grep "^<a href=\"CVE-" www.suse.com/security/cve/index.html  | cut -d"\"" -f2 | sed 's/^/https:\/\/www.suse.com\/security\/cve\//' > www.suse.com/security/cve/urls.txt


wget -x -i www.suse.com/security/cve/urls.txt

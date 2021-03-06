#!/bin/bash



cat www.redhat.com/security/data/metrics/*   | grep -i RHSA | sed 's/[()"<>/,. ]/\n/g' | sed 's/-/:/g' | sed 's/:/-/' | sed 's/:$//' | grep "^RHSA-[0-9][0-9][0-9][0-9]:[0-9]\+$" | sort | uniq | sed 's/^/https:\/\/access.redhat.com\/errata\//' > access.redhat.com/errata/urls.txt

wget --append-output=log/access.redhat.com -x -nc -i access.redhat.com/errata/urls.txt

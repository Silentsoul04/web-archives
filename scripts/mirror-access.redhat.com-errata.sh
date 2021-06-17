#!/bin/bash



cat www.redhat.com/security/data/metrics/*   | grep -i RHSA | sed 's/[()"<>/,. ]/\n/g' | grep ^RHSA-[0-9][0-9][0-9][0-9]:[0-9][0-9][0-9][0-9] | sort | uniq | sed 's/^/https:\/\/access.redhat.com\/errata\//' > access.redhat.com/errata/urls.txt

wget -x -i access.redhat.com/errata/urls.txt

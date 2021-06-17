#!/bin/bash
wget -x https://jvn.jp/en/report/all.html
wget -x https://jvn.jp/report/all.html

workdir=`mktemp -d`

grep "a href=\"/en/jp/JVN" jvn.jp/en/report/all.html | cut -d"\"" -f2 | sed 's/^/wget -nc -x https:\/\/jvn.jp\//' > $workdir/script-en.sh
grep "a href=\"/jp/JVN" jvn.jp/report/all.html | cut -d"\"" -f2 | sed 's/^/wget -nc -x https:\/\/jvn.jp\//' > $workdir/script-jp.sh 

bash $workdir/script-en.sh
bash $workdir/script-jp.sh

rm -rf $workdir

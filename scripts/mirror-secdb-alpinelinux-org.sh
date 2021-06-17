#!/bin/bash

# Use -m because these files update a lot
wget --append-output=log/secdb.alpinelinux.org -m https://secdb.alpinelinux.org/

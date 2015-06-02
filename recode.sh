#!/bin/bash
find /opt/codeback -type f -name "*.aar" -exec cp {} $1 \;

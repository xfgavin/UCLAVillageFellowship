#!/usr/bin/env bash
[ `netstat -an|grep :25|wc -l` -eq 0 ] && sudo /etc/init.d/postfix restart

#!/bin/sh

if [ ! -d "$/app/log" ]; then
  mkdir -p /app/log	
fi

chown -R www-data:www-data /app/log;
chmod -R 755 /app/log;
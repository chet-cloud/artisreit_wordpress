#!/bin/bash
docker build -t artisreit/artisreit_wordpress:latest . 
docker-compose up -d

#!/bin/bash
docker exec headscale-server headscale apikeys create -e 99y | tee api_keys.txt
#!/bin/bash


ansible-playbook -i ./inventory/ --key-file /root/.ssh/ab_id_rsa run.yml

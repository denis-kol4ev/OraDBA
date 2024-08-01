#
# -*- coding: utf-8 -*-

from emcli import *
from emcli.exception import VerbExecutionError
import time

login(username="SYSMAN", password="123", force=True)

v_host_list = ['server111.company.local','server222.company.local']
v_hosts = ''
v_oem_agent_dir = '/opt/oracle/agent13c'
v_oem_agent_platform = '226'
v_oem_agent_port = '3872'
v_host_cred_name = 'ORACLE'
v_host_cred_owner = 'USER_A'
v_agent_image_name ='agent_13.4_gold_image'

for i in v_host_list:
    v_check_agent = list( sql= """ select a.target_name, a.target_type, a.agent_name, a.agent_host_name, h.home_location
    from sysman.mgmt$agents_monitoring_targets a
    inner join SYSMAN.MGMT$OH_INSTALLED_TARGETS h on a.target_name = h.INST_TARGET_NAME
    where a.target_type in ('oracle_emd') and lower(agent_host_name) like '%""" + i + """%' """)

    if not v_check_agent.out()['data']:
        print "Agent on '" + i + "' dose not exists on OEM."
        v_hosts = v_hosts + ";" + i
    else:
        print "Error: Agent on '" + i + "' is alrady installed on OEM."

if v_hosts:
    print "Run installation. Hosts: '" + v_hosts.strip(';') + "', Platform: '" + v_oem_agent_platform + "', Agent_port: '" + v_oem_agent_port + "', Directory: '" + v_oem_agent_dir + "', Agent Gold Image: '" + v_agent_image_name + "'"
    if v_agent_image_name:
        try:
            v_res = submit_add_host(
                wait_for_completion=True,
                host_names=v_hosts.strip(';'),
                platform=v_oem_agent_platform,
                installation_base_directory=v_oem_agent_dir,
                credential_name=v_host_cred_name,
                credential_owner=v_host_cred_owner,
                port=v_oem_agent_port,
                image_name=v_agent_image_name)
            print v_res
        except VerbExecutionError, e:
            print e.error()
            exit(e.exit_code())
    else:
        try:
            v_res = submit_add_host(
                wait_for_completion=True,
                host_names=v_hosts.strip(';'),
                platform=v_oem_agent_platform,
                installation_base_directory=v_oem_agent_dir,
                credential_name=v_host_cred_name,
                credential_owner=v_host_cred_owner,
                port=v_oem_agent_port)
            print v_res
        except VerbExecutionError, e:
            print e.error()
            exit(e.exit_code())
else:
    print "Error: All hosts in list is alrady installed on OEM."
    exit(1)

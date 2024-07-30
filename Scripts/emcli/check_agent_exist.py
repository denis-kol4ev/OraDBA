#
# -*- coding: utf-8 -*-

from emcli import *
from emcli.exception import VerbExecutionError
import time

login(username="SYSMAN", password="123", force=True)

v_host_list = ['server1.company.local','server2.company.local','server3.company.local']

for i in v_host_list:
    v_check_agent = list( sql=""" select a.target_name, a.target_type, a.agent_name, a.agent_host_name, h.home_location
    from sysman.mgmt$agents_monitoring_targets a
    inner join SYSMAN.MGMT$OH_INSTALLED_TARGETS h on a.target_name = h.INST_TARGET_NAME
    where a.target_type in ('oracle_emd') and lower(agent_host_name) like '%""" + i + """%' """)

    if v_check_agent.out()['data']:
        for target in v_check_agent.out()['data']:
            print "AGENT_NAME " + target['AGENT_NAME'] + " HOME_LOCATION " + target['HOME_LOCATION']
    else:
        print "No data found"

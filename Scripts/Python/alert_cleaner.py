# -*- coding: utf-8 -*-

import re
import sys

x = len(sys.argv)
if x == 1:
    print('Для запуска необходимо передать аргументы.')
    print('Воспользуйтесь справкой: ' + sys.argv[0] + ' -h или --help')
    exit(1)
if sys.argv[1] in ('-h','--help'):
    print('Очищаем alert log от записей logminer и записываем результат в новый файл.')
    print('Использование: ' + sys.argv[0] + ' <input_file> <output_file>')
    print('Пример: ' + sys.argv[0] + ' /tmp/alert_prd1.log /tmp/alert_prd1_clean.log')
    exit(1)

in_file = open(sys.argv[1], 'r')
out_file = open(sys.argv[2], 'w')
lines = in_file.readlines()
prev_line = None

for line in lines:
    current_line = line
    if re.match('LOGMINER', current_line):
        prev_line = None
    else:
        if prev_line is not None:
            out_file.write(prev_line)
        prev_line = current_line

if prev_line is not None:
    out_file.write(prev_line)

out_file.close()
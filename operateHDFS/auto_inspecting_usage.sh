#!/bin/bash

echo "start checking hdfs's storage used rate..."
report_file="/home/hdfs/tony/dfsadmin_result.txt"
hdfs dfsadmin -report > ${report_file}
# to get line number of the separating line (----------)
sep_line_num=`sed -e '/----/=' ${report_file} | grep -C 2 '\-\-\-\-' | sed -n '2p'`

start_line_num=`expr ${sep_line_num} + 3`
end_line_num=`wc -l ${report_file} | awk '{print $1}'`
target_file="/home/hdfs/tony/target_file.txt"
# only obtain the content after the separation mark
sed -n "${start_line_num},${end_line_num}p" ${report_file} > ${target_file}

usage_rate_file="/home/hdfs/tony/usage_rate_nums.txt"
cat ${target_file} | grep "DFS Used%" | awk -F ": " '{print $2}' | awk -F "%" '{print $1}' > ${usage_rate_file}
echo 8个数据节点各自HDFS存储使用百分比 "===>"
cat ${usage_rate_file}
max_rate=`cat ${usage_rate_file} | sort | tail -n 1`
min_rate=`cat ${usage_rate_file} | sort | head -n 1`
# [hdfs@kmr-5b9c18fc-gn-7b3518df-master-1-001 tony]$ cat usage_rate_nums.txt | awk '{e+=$1}END{print e,e/NR}'
# 270.5 33.8125
avg_usage_rate=`cat ${usage_rate_file} | awk '{e+=$1}END{print e/NR}'`
echo "数据节点的最大使用率：" ${max_rate} "%"
echo "所有数据节点的平均使用率" ${avg_usage_rate} "%"
echo "数据节点的最小使用率" ${min_rate} "%"

# to calculate the difference between max_usage and average usage, between avg_usage and min_usage
max_avg_diff=`/usr/bin/python max_avg_diff.py ${max_rate} ${avg_usage_rate}`
avg_min_diff=`/usr/bin/python avg_min_diff.py ${avg_usage_rate} ${min_rate}`
echo "最大使用率 与 平均使用率 相差____" ${max_avg_diff}
echo "平均使用率 与 最小使用率 相差____" ${avg_min_diff}
if [ `echo "${max_avg_diff} > 10" | bc` -eq 1 ] && [ `echo "${avg_min_diff} > 10" | bc` -eq 1 ]; then
  echo "HDFS storage-used-rate difference has been greater than 10%, need to run 'rebalance.sh' with user 'root'"
  # then go on manually running your rebalancer-script.
else
  echo "HDFS storage-used-rate difference does not exceed 10%. Nothing to do."
fi

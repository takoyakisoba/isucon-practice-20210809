.PHONY: gogo build stop-services start-services truncate-logs kataribe bench

gogo: stop-services build truncate-logs start-services bench

build:
	cd webapp/golang && make
	scp -C /home/isucon/isucon-practice-20210809/webapp/golang/bin/benchmark_server isucon@172.31.29.195:/home/isucon/webapp/golang/bin/benchmark_server

stop-services:
	sudo systemctl stop envoy
	sudo systemctl stop xsuportal-web-golang
	ssh isucon@172.31.29.195 "sudo systemctl stop xsuportal-api-golang"
	sudo systemctl stop mysql

start-services:
	ssh isucon@172.31.25.150 "sudo systemctl start mysql"
	sleep 1
	ssh isucon@172.31.29.195 "sudo systemctl start xsuportal-api-golang"
	sudo systemctl start xsuportal-web-golang
	sleep 1
	sudo systemctl start envoy
	sleep 3

truncate-logs:
	sudo truncate --size 0 /var/log/envoy/access.log
	sudo truncate --size 0 /var/log/envoy/error.log
	sudo truncate --size 0 /var/log/mysql/error.log
	ssh isucon@172.31.25.150 "sudo truncate --size 0 /var/log/mysql/mysql-slow.log"

kataribe:
	sudo cat /var/log/envoy/access.log | ./kataribe

bench:
	sudo systemd-run  --working-directory=/home/isucon/benchmarker  --pipe  --wait  --collect  --uid=$(id -u) --gid=$(id -g)  --slice=benchmarker.slice  --service-type=oneshot  -p AmbientCapabilities=CAP_NET_BIND_SERVICE  -p CapabilityBoundingSet=CAP_NET_BIND_SERVICE -p LimitNOFILE=2000000 -p TimeoutStartSec=110s   ~isucon/benchmarker/bin/benchmarker -exit-status  -target app.t.isucon.dev  -host-advertise bench.t.isucon.dev -push-service-port 1001

log-save: TS=$(shell date "+%Y%m%d_%H%M%S")
log-save: 
	mkdir /home/isucon/logs/$(TS)
	ssh isucon@172.31.25.150 "mkdir /home/isucon/logs/$(TS)"
	sudo  cp -p /var/log/envoy/access.log  /home/isucon/logs/$(TS)/access.log
	ssh isucon@172.31.25.150 "sudo cp /var/log/mysql/mysql-slow.log  /home/isucon/logs/$(TS)/mysql-slow.log"
	ssh isucon@172.31.25.150 "sudo chmod -R 777 /home/isucon/logs/*"
	scp isucon@172.31.25.150:/home/isucon/logs/$(TS)/mysql-slow.log /home/isucon/logs/$(TS)/mysql-slow.log
	sudo chmod -R 777 /home/isucon/logs/*

log-sync:
	scp -C kataribe.toml ubuntu@18.176.93.9:~/
	rsync -av -e ssh /home/isucon/logs ubuntu@18.176.93.9:/home/ubuntu  

log-push:
	ssh ubuntu@18.176.93.9 "sh push_github.sh"

log-analysis:log-save log-sync log-push

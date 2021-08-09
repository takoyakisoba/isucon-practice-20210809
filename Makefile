.PHONY: gogo build stop-services start-services truncate-logs kataribe bench

gogo: stop-services build truncate-logs start-services bench

build:
	cd webapp/golang && make

stop-services:
	sudo systemctl stop envoy
	sudo systemctl stop xsuportal-web-golang
	sudo systemctl stop mysql

start-services:
	sudo systemctl start mysql
	sleep 5
	sudo systemctl start xsuportal-web-golang
	sudo systemctl start envoy

truncate-logs:
	sudo truncate --size 0 /var/log/envoy/access.log
	sudo truncate --size 0 /var/log/envoy/error.log
	sudo truncate --size 0 /var/log/mysql/error.log
	sudo truncate --size 0 /var/log/mysql/mysql-slow.log

kataribe:
	sudo cat /var/log/envoy/access.log | ./kataribe

bench:
	sudo systemd-run  --working-directory=/home/isucon/benchmarker  --pipe  --wait  --collect  --uid=$(id -u) --gid=$(id -g)  --slice=benchmarker.slice  --service-type=oneshot  -p AmbientCapabilities=CAP_NET_BIND_SERVICE  -p CapabilityBoundingSet=CAP_NET_BIND_SERVICE -p LimitNOFILE=2000000 -p TimeoutStartSec=110s   ~isucon/benchmarker/bin/benchmarker -exit-status  -target app.t.isucon.dev  -host-advertise bench.t.isucon.dev -push-service-port 1001

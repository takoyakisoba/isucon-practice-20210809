.PHONY: gogo build stop-services start-services truncate-logs kataribe bench

gogo: stop-services build truncate-logs start-services bench

build:
	make -C webapp/golang

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
	# cd ../ && sh bench.sh
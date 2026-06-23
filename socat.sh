nohup  socat TCP-LISTEN:9090,fork TCP:master:9090 &
nohup socat TCP-LISTEN:9100,fork TCP:master:9100 &
nohup socat TCP-LISTEN:9093,fork TCP:master:9093 &
nohup socat TCP-LISTEN:9200,fork TCP:node1:9100 &
nohup socat TCP-LISTEN:9300,fork TCP:node2:9100 &
nohup socat TCP-LISTEN:3000,fork TCP:master:3000 &

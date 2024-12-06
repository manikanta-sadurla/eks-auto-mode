# rabbitmq-module/templates/user_data.sh.tpl
#!/bin/bash -xe

# Enable logging
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

# Variables
CLUSTER_NAME="${cluster_name}"
ENVIRONMENT="${environment}"
REGION="${region}"
ENABLE_CLUSTERING="${enable_clustering}"

# Install required packages
yum update -y
yum install -y jq wget logrotate

# Install CloudWatch agent
yum install -y amazon-cloudwatch-agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c ssm:${cloudwatch_config}

# Install Erlang
wget https://packages.erlang-solutions.com/erlang-solutions-2.0-1.noarch.rpm
rpm -Uvh erlang-solutions-2.0-1.noarch.rpm
yum install -y erlang

# Install RabbitMQ
wget https://github.com/rabbitmq/rabbitmq-server/releases/download/v3.11.0/rabbitmq-server-3.11.0-1.el8.noarch.rpm
rpm --import https://www.rabbitmq.com/rabbitmq-signing-key-public.asc
yum install -y rabbitmq-server-3.11.0-1.el8.noarch.rpm

# Configure RabbitMQ
mkdir -p /etc/rabbitmq
cat << EOF > /etc/rabbitmq/rabbitmq.conf
listeners.tcp.default = 5672
management.tcp.port = 15672
management.load_definitions = /etc/rabbitmq/definitions.json
cluster_formation.peer_discovery_backend = rabbit_peer_discovery_aws
cluster_formation.aws.region = ${region}
cluster_formation.aws.use_autoscaling_group = true
cluster_formation.aws.instance_tags.Environment = ${environment}
cluster_formation.aws.instance_tags.Service = rabbitmq
EOF

# Create definitions file with admin user
cat << EOF > /etc/rabbitmq/definitions.json
{
  "users": [
    {
      "name": "admin",
      "password_hash": "$(echo -n "${admin_password}" | openssl dgst -binary -sha256 | base64)",
      "hashing_algorithm": "rabbit_password_hashing_sha256",
      "tags": ["administrator"]
    }
  ],
  "vhosts": [
    {
      "name": "/"
    }
  ],
  "permissions": [
    {
      "user": "admin",
      "vhost": "/",
      "configure": ".*",
      "write": ".*",
      "read": ".*"
    }
  ]
}
EOF

# Set file permissions
chown -R rabbitmq:rabbitmq /etc/rabbitmq
chmod 640 /etc/rabbitmq/rabbitmq.conf
chmod 640 /etc/rabbitmq/definitions.json

# Enable and start RabbitMQ
systemctl enable rabbitmq-server
systemctl start rabbitmq-server

# Enable management plugin
rabbitmq-plugins enable rabbitmq_management
rabbitmq-plugins enable rabbitmq_peer_discovery_aws

# Configure log rotation
cat << EOF > /etc/logrotate.d/rabbitmq
/var/log/rabbitmq/*.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    sharedscripts
    postrotate
        /usr/sbin/rabbitmqctl rotate_logs
    endscript
}
EOF

# If clustering is enabled
if [ "${enable_clustering}" = "true" ]; then
    # Get instance metadata
    TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
    INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/instance-id)
    
    # Set RabbitMQ node name based on instance ID
    echo "NODENAME=rabbit@$INSTANCE_ID" >> /etc/rabbitmq/rabbitmq-env.conf
    
    # Restart RabbitMQ to apply clustering settings
    systemctl restart rabbitmq-server
    
    # Wait for RabbitMQ to start
    sleep 30
    
    # Set cluster name
    rabbitmqctl set_cluster_name "${cluster_name}"
fi

# Setup CloudWatch custom metrics
cat << 'EOF' > /usr/local/bin/rabbitmq-metrics.sh
#!/bin/bash

# Get queue metrics
QUEUE_COUNT=$(rabbitmqctl list_queues | wc -l)
MESSAGES_READY=$(rabbitmqctl list_queues messages_ready | awk '{sum += $1} END {print sum}')
MESSAGES_UNACK=$(rabbitmqctl list_queues messages_unacknowledged | awk '{sum += $1} END {print sum}')

# Get node metrics
MEMORY_USED=$(rabbitmqctl status | grep -A 1 "memory" | grep total | awk '{print $2}' | tr -d ',')
DISK_FREE=$(rabbitmqctl status | grep disk_free | awk '{print $2}' | tr -d ',')
ERLANG_PROCESSES=$(rabbitmqctl status | grep processes | head -1 | awk '{print $2}' | tr -d ',')

# Push metrics to CloudWatch
aws cloudwatch put-metric-data --namespace RabbitMQ/Custom --region ${region} --metric-data \
    "[
        {
            \"MetricName\": \"QueueCount\",
            \"Value\": $QUEUE_COUNT,
            \"Unit\": \"Count\"
        },
        {
            \"MetricName\": \"MessagesReady\",
            \"Value\": $MESSAGES_READY,
            \"Unit\": \"Count\"
        },
        {
            \"MetricName\": \"MessagesUnacknowledged\",
            \"Value\": $MESSAGES_UNACK,
            \"Unit\": \"Count\"
        },
        {
            \"MetricName\": \"MemoryUsed\",
            \"Value\": $MEMORY_USED,
            \"Unit\": \"Bytes\"
        },
        {
            \"MetricName\": \"DiskFree\",
            \"Value\": $DISK_FREE,
            \"Unit\": \"Bytes\"
        },
        {
            \"MetricName\": \"ErlangProcesses\",
            \"Value\": $ERLANG_PROCESSES,
            \"Unit\": \"Count\"
        }
    ]"
EOF

chmod +x /usr/local/bin/rabbitmq-metrics.sh

# Setup cron job for metrics collection
echo "*/5 * * * * root /usr/local/bin/rabbitmq-metrics.sh" > /etc/cron.d/rabbitmq-metrics

# Setup basic monitoring script
cat << 'EOF' > /usr/local/bin/check-rabbitmq.sh
#!/bin/bash

# Check RabbitMQ service status
systemctl is-active --quiet rabbitmq-server
if [ $? -ne 0 ]; then
    systemctl restart rabbitmq-server
    echo "RabbitMQ service was down, restarted at $(date)" >> /var/log/rabbitmq/monitoring.log
fi

# Check disk space
DISK_FREE_LIMIT=5368709120  # 5GB in bytes
DISK_FREE=$(df -B1 /var/lib/rabbitmq | awk 'NR==2 {print $4}')
if [ $DISK_FREE -lt $DISK_FREE_LIMIT ]; then
    echo "Low disk space warning at $(date)" >> /var/log/rabbitmq/monitoring.log
fi
EOF

chmod +x /usr/local/bin/check-rabbitmq.sh

# Setup monitoring cron job
echo "*/2 * * * * root /usr/local/bin/check-rabbitmq.sh" > /etc/cron.d/check-rabbitmq

# Signal successful completion
/opt/aws/bin/cfn-signal -e $? --stack ${cluster_name} --resource AutoScalingGroup --region ${region}

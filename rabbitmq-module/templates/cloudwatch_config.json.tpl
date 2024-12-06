{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "root"
  },
  "metrics": {
    "namespace": "RabbitMQ",
    "metrics_collected": {
      "rabbitmq": {
        "metrics_collection_interval": 60,
        "measurement": [
          {"name": "queue_messages", "unit": "Count"},
          {"name": "connection_count", "unit": "Count"},
          {"name": "memory_used", "unit": "Bytes"},
          {"name": "disk_free", "unit": "Bytes"},
          {"name": "erlang_processes_used", "unit": "Count"},
          {"name": "node_up", "unit": "Count"}
        ]
      },
      "mem": {
        "measurement": [
          "used_percent",
          "mem_total",
          "mem_free"
        ]
      },
      "disk": {
        "measurement": [
          "used_percent",
          "free",
          "total"
        ],
        "resources": [
          "*"
        ]
      }
    }
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/rabbitmq/*.log",
            "log_group_name": "/aws/rabbitmq/${cluster_name}",
            "log_stream_name": "{instance_id}",
            "timestamp_format": "%Y-%m-%d %H:%M:%S",
            "retention_in_days": 30
          }
        ]
      }
    }
  }
}
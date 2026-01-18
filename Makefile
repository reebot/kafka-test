.PHONY: help clean

# Default target
help:
	@echo "Message Queue Systems - Available Commands"
	@echo "=========================================="
	@echo ""
	@echo "Kafka Commands:"
	@echo "  make kafka-up          - Start Kafka and ZooKeeper"
	@echo "  make kafka-down        - Stop Kafka and ZooKeeper"
	@echo "  make kafka-producer    - Run Kafka producer"
	@echo "  make kafka-consumer    - Run Kafka consumer"
	@echo "  make kafka-logs        - View Kafka logs"
	@echo ""
	@echo "RabbitMQ Commands:"
	@echo "  make rabbitmq-up       - Start RabbitMQ"
	@echo "  make rabbitmq-down     - Stop RabbitMQ"
	@echo "  make rabbitmq-producer - Run RabbitMQ producer"
	@echo "  make rabbitmq-consumer - Run RabbitMQ consumer"
	@echo "  make rabbitmq-logs     - View RabbitMQ logs"
	@echo ""
	@echo "Redis Commands:"
	@echo "  make redis-up          - Start Redis"
	@echo "  make redis-down        - Stop Redis"
	@echo "  make redis-publisher   - Run Redis publisher"
	@echo "  make redis-subscriber  - Run Redis subscriber"
	@echo "  make redis-logs        - View Redis logs"
	@echo ""
	@echo "NSQ Commands:"
	@echo "  make nsq-up            - Start NSQ cluster"
	@echo "  make nsq-down          - Stop NSQ cluster"
	@echo "  make nsq-producer      - Run NSQ producer"
	@echo "  make nsq-consumer      - Run NSQ consumer"
	@echo "  make nsq-logs          - View NSQ logs"
	@echo ""
	@echo "Pulsar Commands:"
	@echo "  make pulsar-up         - Start Pulsar"
	@echo "  make pulsar-down       - Stop Pulsar"
	@echo "  make pulsar-producer   - Run Pulsar producer"
	@echo "  make pulsar-consumer   - Run Pulsar consumer"
	@echo "  make pulsar-logs       - View Pulsar logs"
	@echo ""
	@echo "ActiveMQ Commands:"
	@echo "  make activemq-up       - Start ActiveMQ"
	@echo "  make activemq-down     - Stop ActiveMQ"
	@echo "  make activemq-producer - Run ActiveMQ producer"
	@echo "  make activemq-consumer - Run ActiveMQ consumer"
	@echo "  make activemq-logs     - View ActiveMQ logs"
	@echo ""
	@echo "General Commands:"
	@echo "  make all-up            - Start all message queue services"
	@echo "  make all-down          - Stop all message queue services"
	@echo "  make clean             - Stop all services and clean up"
	@echo "  make deps              - Install Go dependencies"
	@echo ""

# Kafka targets
kafka-up:
	@echo "Starting Kafka and ZooKeeper..."
	@docker-compose up -d
	@echo "Waiting for Kafka to be ready..."
	@sleep 10
	@echo "Kafka is ready on port 50891"
	@echo "Kafka UI: http://localhost:8080"

kafka-down:
	@docker-compose down

kafka-producer:
	@echo "Running Kafka producer..."
	@go run producer.go getting-started.properties

kafka-consumer:
	@echo "Running Kafka consumer..."
	@go run consumer.go getting-started.properties

kafka-logs:
	@docker-compose logs -f kafka

# RabbitMQ targets
rabbitmq-up:
	@echo "Starting RabbitMQ..."
	@cd rabbitmq && docker-compose up -d
	@echo "RabbitMQ Management UI: http://localhost:15672"
	@echo "Credentials: user/password"

rabbitmq-down:
	@cd rabbitmq && docker-compose down

rabbitmq-producer:
	@echo "Running RabbitMQ producer..."
	@cd rabbitmq && go run producer.go

rabbitmq-consumer:
	@echo "Running RabbitMQ consumer..."
	@cd rabbitmq && go run consumer.go

rabbitmq-logs:
	@cd rabbitmq && docker-compose logs -f rabbitmq

# Redis targets
redis-up:
	@echo "Starting Redis..."
	@cd redis && docker-compose up -d
	@echo "Redis running on port 6379"
	@echo "RedisInsight UI: http://localhost:8001"

redis-down:
	@cd redis && docker-compose down

redis-publisher:
	@echo "Running Redis publisher..."
	@cd redis && go run pub.go

redis-subscriber:
	@echo "Running Redis subscriber..."
	@cd redis && go run sub.go

redis-logs:
	@cd redis && docker-compose logs -f redis

# NSQ targets
nsq-up:
	@echo "Starting NSQ cluster..."
	@cd nsq && docker-compose up -d
	@echo "NSQ Admin UI: http://localhost:4171"

nsq-down:
	@cd nsq && docker-compose down

nsq-producer:
	@echo "Running NSQ producer..."
	@cd nsq && go run producer.go

nsq-consumer:
	@echo "Running NSQ consumer..."
	@cd nsq && go run consumer.go

nsq-logs:
	@cd nsq && docker-compose logs -f nsqd

# Pulsar targets
pulsar-up:
	@echo "Starting Pulsar..."
	@cd pulsar && docker-compose up -d
	@echo "Waiting for Pulsar to be ready (this may take 60 seconds)..."
	@sleep 60
	@echo "Pulsar is ready on port 6650"
	@echo "Pulsar Manager: http://localhost:9527"

pulsar-down:
	@cd pulsar && docker-compose down

pulsar-producer:
	@echo "Running Pulsar producer..."
	@cd pulsar && go run producer.go

pulsar-consumer:
	@echo "Running Pulsar consumer..."
	@cd pulsar && go run consumer.go

pulsar-logs:
	@cd pulsar && docker-compose logs -f pulsar

# ActiveMQ targets
activemq-up:
	@echo "Starting ActiveMQ..."
	@cd activemq && docker-compose up -d
	@echo "ActiveMQ Web Console: http://localhost:8161"
	@echo "Credentials: admin/admin"

activemq-down:
	@cd activemq && docker-compose down

activemq-producer:
	@echo "Running ActiveMQ producer..."
	@cd activemq && go run producer.go

activemq-consumer:
	@echo "Running ActiveMQ consumer..."
	@cd activemq && go run consumer.go

activemq-logs:
	@cd activemq && docker-compose logs -f activemq

# General targets
all-up:
	@echo "Starting all message queue services..."
	@make kafka-up
	@make rabbitmq-up
	@make redis-up
	@make nsq-up
	@make pulsar-up
	@make activemq-up
	@echo ""
	@echo "All services started!"
	@echo "========================"
	@echo "Kafka UI:        http://localhost:8080"
	@echo "RabbitMQ UI:     http://localhost:15672 (user/password)"
	@echo "Redis UI:        http://localhost:8001"
	@echo "NSQ Admin:       http://localhost:4171"
	@echo "Pulsar Manager:  http://localhost:9527"
	@echo "ActiveMQ UI:     http://localhost:8161 (admin/admin)"

all-down:
	@echo "Stopping all message queue services..."
	@make kafka-down
	@make rabbitmq-down
	@make redis-down
	@make nsq-down
	@make pulsar-down
	@make activemq-down
	@echo "All services stopped"

clean: all-down
	@echo "Cleaning up Docker volumes..."
	@docker volume prune -f
	@echo "Cleanup complete"

deps:
	@echo "Installing Go dependencies..."
	@go mod download
	@echo "Dependencies installed"

# Message Queue Systems - A Beginner's Guide

A hands-on educational repository comparing **7 different message queue systems** with practical Go examples. Perfect for developers learning about distributed messaging, event streaming, and asynchronous communication.

## 📚 What Are Message Queues?

Message queues are middleware systems that enable **asynchronous communication** between different parts of an application. Instead of components talking directly to each other, they send messages to a queue, which other components can read when they're ready.

**Why use message queues?**
- **Decouple services**: Producer and consumer don't need to know about each other
- **Handle traffic spikes**: Queue absorbs bursts of messages
- **Ensure reliability**: Messages aren't lost if a service goes down
- **Scale independently**: Add more consumers to process messages faster
- **Enable event-driven architecture**: React to events in real-time

## 🎯 What's In This Repository?

This repository provides **side-by-side comparisons** of 7 popular message queue systems, each with working producer and consumer examples in Go:

| System | Use Case | Protocol | Best For |
|--------|----------|----------|----------|
| **Kafka** | Event streaming, log aggregation | Kafka Protocol | High-throughput event streaming, real-time analytics |
| **RabbitMQ** | Task queues, RPC | AMQP | Traditional messaging, task distribution |
| **Redis** | Simple pub/sub | Redis Protocol | Lightweight pub/sub, caching with messaging |
| **Apache Pulsar** | Multi-tenant messaging | Pulsar Protocol | Cloud-native, geo-replication, multi-tenancy |
| **NSQ** | Distributed messaging | TCP | Real-time distributed messaging at scale |
| **ActiveMQ** | Enterprise messaging | STOMP/JMS | Enterprise integration, JMS compatibility |
| **Upstash Kafka** | Serverless Kafka | Kafka Protocol | Serverless/cloud-hosted Kafka |

📖 **New to message queues?** Read our [Comparison Guide](COMPARISON.md) to understand when to use each system.

## 🚀 Quick Start

### Prerequisites

- **Docker & Docker Compose** (to run message queue services)
- **Go 1.21.3+** (to run the examples)
- **Git** (to clone this repository)

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/kafka-test.git
cd kafka-test

# Install Go dependencies
go mod download
```

### Running Your First Example

Let's start with **Kafka** (the most popular streaming platform):

```bash
# 1. Start Kafka using Docker Compose
docker-compose up -d

# 2. Run the consumer (in one terminal)
go run consumer.go getting-started.properties

# 3. Run the producer (in another terminal)
go run producer.go getting-started.properties

# 4. Watch messages flow from producer to consumer!
```

You should see output like:
```
Produced event to topic purchases: key = eabara     value = book
Produced event to topic purchases: key = jsmith     value = alarm clock
```

**Stop Kafka when done:**
```bash
docker-compose down
```

## 📂 Repository Structure

```
kafka-test/
├── producer.go              # Kafka producer (Confluent client)
├── consumer.go              # Kafka consumer (Confluent client)
├── coins.go                 # Kafka producer (Segmentio client + SASL auth)
├── upstash.go              # Upstash Kafka producer (cloud-based)
├── docker-compose.yml       # Kafka + Zookeeper setup
├── getting-started.properties  # Kafka configuration
│
├── rabbitmq/               # RabbitMQ examples (AMQP)
│   ├── producer.go
│   ├── consumer.go
│   ├── docker-compose.yml
│   └── guide.md
│
├── redis/                  # Redis Pub/Sub examples
│   ├── pub.go
│   ├── sub.go
│   ├── docker-compose.yml
│   └── guide.md
│
├── pulsar/                 # Apache Pulsar examples
│   ├── producer.go
│   ├── consumer.go
│   ├── docker-compose.yml
│   └── guide.md
│
├── nsq/                    # NSQ examples
│   ├── producer.go
│   ├── consumer.go
│   ├── docker-compose.yml
│   └── guide.md
│
└── activemq/               # ActiveMQ examples (STOMP)
    ├── producer.go
    ├── consumer.go
    ├── docker-compose.yml
    └── guide.md
```

## 🎓 System-Specific Guides

Each message queue system has its own guide with setup instructions and explanations:

- **[Kafka Guide](KAFKA_GUIDE.md)** - Event streaming platform for high-throughput data pipelines
- **[RabbitMQ Guide](rabbitmq/guide.md)** - Traditional message broker for task queues
- **[Redis Guide](redis/guide.md)** - Lightweight pub/sub for simple messaging
- **[Pulsar Guide](pulsar/guide.md)** - Cloud-native messaging with multi-tenancy
- **[NSQ Guide](nsq/guide.md)** - Distributed real-time messaging
- **[ActiveMQ Guide](activemq/guide.md)** - Enterprise messaging with JMS support

## 🔍 How to Choose a Message Queue?

Not sure which system to use? Here's a quick decision tree:

1. **Need high-throughput event streaming?** → **Kafka** or **Pulsar**
2. **Building task queues or RPC?** → **RabbitMQ**
3. **Need simple pub/sub with caching?** → **Redis**
4. **Need multi-tenancy or geo-replication?** → **Pulsar**
5. **Want distributed topology without a broker?** → **NSQ**
6. **Need JMS compatibility for enterprise?** → **ActiveMQ**

📊 **Read the full comparison:** [COMPARISON.md](COMPARISON.md)

## 💡 Learning Path

**For Complete Beginners:**
1. Start with **Redis** (simplest pub/sub pattern)
2. Move to **RabbitMQ** (traditional message queue)
3. Graduate to **Kafka** (event streaming)

**For Production Use:**
1. Understand your use case (streaming vs messaging)
2. Read [COMPARISON.md](COMPARISON.md)
3. Test with Docker Compose
4. Benchmark with your expected load

## 🛠️ Using the Makefile

We provide a Makefile for convenience:

```bash
# See all available commands
make help

# Start a specific system
make kafka-up
make rabbitmq-up
make redis-up

# Run producer/consumer
make kafka-producer
make kafka-consumer

# Stop all services
make clean
```

## 📖 Example Code Walkthrough

All examples follow the same pattern:

### Producer Pattern
```go
// 1. Create a producer/client
producer := createProducer()

// 2. Send messages
for i := 0; i < 10; i++ {
    producer.Send(message)
}

// 3. Clean up
producer.Close()
```

### Consumer Pattern
```go
// 1. Create a consumer/subscriber
consumer := createConsumer()

// 2. Process messages (usually in a loop)
for message := range consumer.Messages() {
    handleMessage(message)
}

// 3. Clean up
consumer.Close()
```

Each system's implementation shows these patterns with system-specific details.

## 🔧 Troubleshooting

**Common Issues:**

1. **Port already in use**
   ```bash
   # Check what's using the port
   lsof -i :9092  # Kafka
   lsof -i :5672  # RabbitMQ

   # Stop conflicting service or change port in docker-compose.yml
   ```

2. **Cannot connect to Docker**
   ```bash
   # Make sure Docker is running
   docker ps

   # Restart Docker Desktop/daemon if needed
   ```

3. **Go module errors**
   ```bash
   # Clean module cache and reinstall
   go clean -modcache
   go mod download
   ```

4. **Messages not appearing**
   - Make sure you started the consumer **before** the producer
   - Check Docker logs: `docker-compose logs`
   - Verify the topic/queue name matches in both producer and consumer

## 🤝 Contributing

Contributions are welcome! This is an educational project, so clarity and beginner-friendliness are priorities.

**Ideas for contributions:**
- Add more message queue systems (NATS, Amazon SQS, Google Pub/Sub)
- Improve code comments and explanations
- Add error handling examples
- Create benchmark comparisons
- Add diagrams showing architecture

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## 📝 License

This project is licensed under the MIT License - see [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

This repository uses official client libraries from each message queue provider:
- [Confluent Kafka Go](https://github.com/confluentinc/confluent-kafka-go)
- [Segmentio Kafka Go](https://github.com/segmentio/kafka-go)
- [Apache Pulsar Go Client](https://github.com/apache/pulsar-client-go)
- [RabbitMQ AMQP Go](https://github.com/streadway/amqp)
- [NSQ Go](https://github.com/nsqio/go-nsq)
- [Go-Stomp](https://github.com/go-stomp/stomp)
- [Go-Redis](https://github.com/go-redis/redis)

## 📚 Additional Resources

**Learn More About Message Queues:**
- [What is a Message Queue?](https://www.cloudamqp.com/blog/what-is-message-queuing.html)
- [Kafka vs RabbitMQ](https://www.confluent.io/kafka-vs-rabbitmq/)
- [Understanding Event-Driven Architecture](https://aws.amazon.com/event-driven-architecture/)

**Official Documentation:**
- [Kafka Documentation](https://kafka.apache.org/documentation/)
- [RabbitMQ Tutorials](https://www.rabbitmq.com/getstarted.html)
- [Pulsar Documentation](https://pulsar.apache.org/docs/)
- [Redis Pub/Sub](https://redis.io/topics/pubsub)
- [NSQ Documentation](https://nsq.io/)
- [ActiveMQ Documentation](https://activemq.apache.org/)

---

**Happy Learning! 🚀** If this repository helped you, please give it a star ⭐

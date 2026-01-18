# Kafka Quick Start Guide

## What is Apache Kafka?

Apache Kafka is a **distributed event streaming platform** designed for high-throughput, fault-tolerant, real-time data pipelines. Think of it as a "commit log" that stores streams of events that can be read by multiple consumers at different speeds.

### Key Concepts

- **Producer**: Application that publishes (writes) events to Kafka
- **Consumer**: Application that subscribes to (reads) events from Kafka
- **Topic**: Category or feed name to which events are published (like "purchases", "user-clicks", "logs")
- **Partition**: Topics are split into partitions for scalability and parallel processing
- **Broker**: Kafka server that stores data and serves clients
- **ZooKeeper**: Coordination service that manages the Kafka cluster

### When to Use Kafka

✅ **Use Kafka for:**
- High-volume event streaming (millions of events/second)
- Real-time data pipelines (logs, metrics, user activity)
- Event sourcing and CQRS architectures
- Message replay (re-process historical events)
- Microservices communication with event-driven patterns

❌ **Don't use Kafka for:**
- Simple request-reply (RPC) patterns
- Low message volume (< 1000 messages/sec)
- Message priority or complex routing needs

## Architecture Overview

```
Producer → Topic (partitioned) → Consumers
                 ↓
           Stored on disk
         (retained for days)
```

**Key Features:**
- Messages are **retained** for a configurable time (default: 7 days)
- Multiple consumers can read the **same message** independently
- Messages are **ordered** within a partition
- **Horizontal scaling** by adding more partitions and brokers

## Setup Instructions

### 1. Start Kafka with Docker Compose

```bash
# Navigate to the project root
cd /path/to/kafka-test

# Start Kafka and ZooKeeper
docker-compose up -d

# Verify services are running
docker-compose ps
```

You should see:
- `zookeeper` - Running on port 2181
- `kafka` - Running on port 50891 (and 9092)
- `kafka-ui` - Running on port 8080 (optional UI)

### 2. Verify Kafka is Ready

```bash
# Check Kafka logs
docker-compose logs kafka

# Wait for: "Kafka Server started"
```

### 3. Access Kafka UI (Optional)

Open your browser and navigate to:
- **Kafka UI**: http://localhost:8080

This provides a visual interface to:
- View topics and partitions
- Monitor consumer groups
- See message throughput
- Browse messages

## Running the Examples

### Example 1: Basic Producer & Consumer

This repository includes two Kafka examples using different client libraries.

#### Using Confluent Kafka Client

**Terminal 1 - Start Consumer:**
```bash
# Run consumer (it will wait for messages)
go run consumer.go getting-started.properties
```

**Terminal 2 - Run Producer:**
```bash
# Run producer (sends 10 messages)
go run producer.go getting-started.properties
```

**Expected Output (Consumer):**
```
Consumed event from topic purchases: key = eabara     value = book
Consumed event from topic purchases: key = jsmith     value = alarm clock
Consumed event from topic purchases: key = sgarcia    value = t-shirts
...
```

**Expected Output (Producer):**
```
Produced event to topic purchases: key = eabara     value = book
Produced event to topic purchases: key = jsmith     value = alarm clock
Produced event to topic purchases: key = sgarcia    value = t-shirts
...
```

### Example 2: Alternative Client (Segmentio) with Authentication

**Using coins.go (Segmentio Kafka client with SASL/SCRAM):**

This example shows how to connect to Kafka with authentication (useful for cloud Kafka services).

```bash
# Set environment variables for Upstash Kafka (or any SASL-enabled Kafka)
export KAFKA_BROKER="your-kafka-broker:9092"
export KAFKA_USERNAME="your-username"
export KAFKA_PASSWORD="your-password"

# Run the producer
go run coins.go
```

This demonstrates:
- TLS encryption
- SASL/SCRAM authentication
- Environment-based configuration

## Understanding the Code

### Producer Code (producer.go)

```go
// 1. Read configuration from properties file
conf := ReadConfig(configFile)

// 2. Create producer
p, err := kafka.NewProducer(&conf)

// 3. Send messages asynchronously
p.Produce(&kafka.Message{
    TopicPartition: kafka.TopicPartition{
        Topic:     &topic,
        Partition: kafka.PartitionAny,  // Let Kafka choose partition
    },
    Key:   []byte(key),    // Messages with same key go to same partition
    Value: []byte(data),   // Actual message payload
}, nil)

// 4. Wait for all messages to be delivered
p.Flush(15 * 1000)  // Wait up to 15 seconds
p.Close()
```

**Key Concepts:**
- **Async Production**: Messages are sent in the background for better performance
- **Partitioning**: Kafka uses the message key to determine which partition to write to
- **Delivery Reports**: Producer tracks which messages were successfully sent
- **Flush**: Ensures all pending messages are sent before exiting

### Consumer Code (consumer.go)

```go
// 1. Create consumer with group ID
c, err := kafka.NewConsumer(&conf)

// 2. Subscribe to topics
c.SubscribeTopics([]string{topic}, nil)

// 3. Poll for messages in a loop
for run {
    msg, err := c.ReadMessage(time.Second)
    if err == nil {
        fmt.Printf("Consumed event: key = %s value = %s\n",
            string(msg.Key), string(msg.Value))
    }
}

// 4. Clean up
c.Close()
```

**Key Concepts:**
- **Consumer Groups**: Consumers in the same group share partitions (load balancing)
- **Polling**: Consumer continuously polls for new messages
- **Auto Offset Management**: Kafka tracks which messages have been consumed
- **Graceful Shutdown**: Handle SIGINT/SIGTERM to close cleanly

## Configuration

### Configuration File (getting-started.properties)

```properties
bootstrap.servers=localhost:50891
```

**Common Configuration Options:**

```properties
# Producer settings
acks=all                          # Wait for all replicas to acknowledge
compression.type=snappy           # Compress messages
batch.size=16384                  # Batch size in bytes

# Consumer settings
group.id=my-consumer-group        # Consumer group name
auto.offset.reset=earliest        # Start from beginning if no offset
enable.auto.commit=true           # Automatically commit offsets
```

## Common Operations

### Create a Topic

```bash
# Using Docker
docker exec -it kafka kafka-topics --create \
  --bootstrap-server localhost:50891 \
  --topic my-topic \
  --partitions 3 \
  --replication-factor 1
```

### List Topics

```bash
docker exec -it kafka kafka-topics --list \
  --bootstrap-server localhost:50891
```

### View Topic Details

```bash
docker exec -it kafka kafka-topics --describe \
  --bootstrap-server localhost:50891 \
  --topic purchases
```

### View Consumer Groups

```bash
docker exec -it kafka kafka-consumer-groups --list \
  --bootstrap-server localhost:50891
```

### Consume Messages from CLI

```bash
# Consume from beginning
docker exec -it kafka kafka-console-consumer \
  --bootstrap-server localhost:50891 \
  --topic purchases \
  --from-beginning
```

## Troubleshooting

### Issue: Cannot connect to Kafka

**Error:** `Failed to create producer: Local: Broker transport failure`

**Solutions:**
1. Verify Kafka is running: `docker-compose ps`
2. Check Kafka logs: `docker-compose logs kafka`
3. Verify port is correct: `localhost:50891`
4. Ensure ZooKeeper is healthy

### Issue: Producer hangs or times out

**Symptoms:** Producer doesn't complete or times out on Flush()

**Solutions:**
1. Check topic exists (auto-create should be enabled)
2. Increase Flush timeout: `p.Flush(30 * 1000)`
3. Check network connectivity
4. Verify broker configuration

### Issue: Consumer not receiving messages

**Symptoms:** Consumer runs but shows no messages

**Solutions:**
1. Run producer AFTER consumer is ready
2. Check `auto.offset.reset` configuration
3. Verify you're using the same topic name
4. Try consuming from beginning: `auto.offset.reset=earliest`

### Issue: Port 50891 already in use

**Error:** `Bind for 0.0.0.0:50891 failed: port is already allocated`

**Solutions:**
```bash
# Find process using the port
lsof -i :50891

# Stop existing Kafka
docker-compose down

# Or change port in docker-compose.yml and getting-started.properties
```

## Performance Tips

### For Producers:
- Use **batching** to send multiple messages at once
- Enable **compression** (snappy, lz4, or zstd)
- Use **async send** with callback for high throughput
- Tune `linger.ms` and `batch.size` for your use case

### For Consumers:
- Use **consumer groups** for parallel processing
- Increase `fetch.min.bytes` for batch processing
- Process messages in batches when possible
- Use manual offset commit for exactly-once semantics

## Next Steps

1. **Experiment**: Try changing the number of messages, topics, or keys
2. **Multiple Consumers**: Run multiple consumer instances to see load balancing
3. **Partitions**: Create topics with multiple partitions
4. **Stream Processing**: Explore Kafka Streams for real-time processing
5. **Production Ready**: Learn about replication, security, and monitoring

## Additional Resources

- [Kafka Documentation](https://kafka.apache.org/documentation/)
- [Confluent Kafka Go Client](https://github.com/confluentinc/confluent-kafka-go)
- [Kafka Use Cases](https://kafka.apache.org/uses)
- [Kafka Design Principles](https://kafka.apache.org/documentation/#design)

---

**Ready to learn more?** Check out the [COMPARISON.md](COMPARISON.md) to see how Kafka compares to other message queue systems!

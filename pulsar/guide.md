# Apache Pulsar Quick Start Guide

## What is Apache Pulsar?

Apache Pulsar is a **cloud-native distributed messaging and streaming platform** originally developed by Yahoo. It combines the best features of traditional message queues and event streaming platforms with unique capabilities like multi-tenancy and geo-replication.

### Key Concepts

- **Producer**: Application that publishes messages to topics
- **Consumer**: Application that subscribes to topics and processes messages
- **Topic**: Named channel for messages (e.g., "persistent://public/default/my-topic")
- **Subscription**: Named cursor that tracks message consumption
- **Broker**: Stateless server that handles message routing
- **BookKeeper**: Distributed log storage system (persistence layer)
- **Tenant**: Top-level isolation unit for multi-tenancy
- **Namespace**: Grouping of topics within a tenant

### When to Use Pulsar

✅ **Use Pulsar for:**
- Cloud-native applications with multi-tenancy needs
- Geo-replication across multiple data centers
- Unified messaging and streaming (queuing + streaming in one)
- Independent scaling of compute and storage
- High-throughput event streaming (similar to Kafka)
- Complex organization structures (multiple teams/projects)

❌ **Don't use Pulsar for:**
- Simple use cases (too complex)
- Small teams without ops expertise
- When ecosystem maturity matters (Kafka has more tools)
- Limited resources (requires BookKeeper + brokers)

## Architecture Overview

```
Producer → Broker (stateless) → BookKeeper (storage) → Consumer
                                     ↓
                              Tiered Storage (S3, etc.)
```

**Key Features:**
- **Layered Architecture**: Separate compute (brokers) from storage (BookKeeper)
- **Multi-tenancy**: Built-in isolation for different teams/applications
- **Geo-replication**: Replicate data across regions automatically
- **Flexible consumption**: Exclusive, shared, failover, or key-shared subscriptions
- **Tiered storage**: Hot data in BookKeeper, cold data in S3/GCS

## Setup Instructions

### 1. Start Pulsar with Docker Compose

```bash
# Navigate to the Pulsar directory
cd /path/to/kafka-test/pulsar

# Start Pulsar standalone (includes broker + BookKeeper)
docker-compose up -d

# Verify services are running
docker-compose ps
```

You should see:
- `pulsar` - Running on ports 6650 (broker), 8080 (HTTP)
- `pulsar-manager` - Running on port 9527 (optional UI)

### 2. Wait for Pulsar to be Ready

```bash
# Check Pulsar logs
docker-compose logs -f pulsar

# Wait for: "messaging service is ready"
```

This may take 30-60 seconds on first start.

### 3. Access Pulsar Manager (Optional)

Open your browser and navigate to:
- **Pulsar Manager**: http://localhost:9527

**First time setup:**
1. Create admin account (username/password)
2. Add environment:
   - Service URL: http://pulsar:8080
   - Broker URL: pulsar://pulsar:6650

This provides:
- Topic management
- Subscription monitoring
- Performance metrics
- Namespace administration

## Running the Examples

### Terminal 1 - Start Consumer

```bash
# Navigate to Pulsar directory
cd pulsar

# Run consumer (it will wait for messages)
go run consumer.go
```

**Output:**
```
Consumer created for topic: my-topic
Waiting for messages... (Press Ctrl+C to exit)
```

### Terminal 2 - Run Producer

```bash
# In a new terminal, navigate to Pulsar directory
cd pulsar

# Run producer (sends 10 messages)
go run producer.go
```

**Expected Output (Producer):**
```
Producer created for topic: my-topic
Sent: hello-0
Sent: hello-1
Sent: hello-2
...
Sent: hello-9
Producer closed
```

**Expected Output (Consumer):**
```
Received message: hello-0
Received message: hello-1
Received message: hello-2
...
```

## Understanding the Code

### Producer Code (producer.go)

```go
// 1. Create Pulsar client
client, err := pulsar.NewClient(pulsar.ClientOptions{
    URL: "pulsar://localhost:6650",
})

// 2. Create producer for a topic
producer, err := client.CreateProducer(pulsar.ProducerOptions{
    Topic: "my-topic",
})

// 3. Send messages
_, err = producer.Send(context.Background(), &pulsar.ProducerMessage{
    Payload: []byte("Hello Pulsar!"),
})

// 4. Clean up
producer.Close()
client.Close()
```

**Key Concepts:**
- **Context**: Use Go context for timeouts and cancellation
- **Synchronous Send**: Waits for acknowledgment
- **Schema**: Optional schema validation (Avro, JSON, Protobuf)
- **Batching**: Automatic batching for performance

### Consumer Code (consumer.go)

```go
// 1. Create Pulsar client
client, err := pulsar.NewClient(pulsar.ClientOptions{
    URL: "pulsar://localhost:6650",
})

// 2. Create consumer with subscription
consumer, err := client.Subscribe(pulsar.ConsumerOptions{
    Topic:            "my-topic",
    SubscriptionName: "my-subscription",
    Type:             pulsar.Exclusive,  // Subscription type
})

// 3. Receive and acknowledge messages
for {
    msg, err := consumer.Receive(context.Background())
    fmt.Printf("Received: %s\n", string(msg.Payload()))

    // Acknowledge message (important!)
    consumer.Acknowledge(msg)
}

// 4. Clean up
consumer.Close()
client.Close()
```

**Key Concepts:**
- **Subscriptions**: Track consumption progress independently
- **Subscription Types**: Exclusive, Shared, Failover, Key_Shared
- **Acknowledgment**: Must explicitly acknowledge messages
- **Negative Ack**: Can reject messages for redelivery

## Subscription Types

Pulsar supports 4 subscription types:

### 1. Exclusive (Default)

Only **one consumer** can subscribe. Messages delivered in order.

```go
Type: pulsar.Exclusive
```

**Use for:** Single consumer, ordered processing

### 2. Shared

**Multiple consumers** share subscription. Messages distributed round-robin.

```go
Type: pulsar.Shared
```

**Use for:** Parallel processing, load distribution

### 3. Failover

**Multiple consumers**, but only **one active**. Others are standby.

```go
Type: pulsar.Failover
```

**Use for:** High availability with ordering

### 4. Key_Shared

**Multiple consumers**. Messages with same key go to same consumer.

```go
Type: pulsar.KeyShared
```

**Use for:** Parallel processing with key-based ordering

## Common Operations

### List Topics

```bash
# Using pulsar-admin
docker exec -it pulsar bin/pulsar-admin topics list public/default
```

### Create a Topic

```bash
# Topics are auto-created by default, but you can create manually
docker exec -it pulsar bin/pulsar-admin topics create \
  persistent://public/default/my-topic
```

### View Topic Stats

```bash
docker exec -it pulsar bin/pulsar-admin topics stats \
  persistent://public/default/my-topic
```

### List Subscriptions

```bash
docker exec -it pulsar bin/pulsar-admin topics subscriptions \
  persistent://public/default/my-topic
```

### Delete a Subscription

```bash
docker exec -it pulsar bin/pulsar-admin topics delete-subscription \
  persistent://public/default/my-topic \
  -s my-subscription
```

### Consume from CLI

```bash
# Consume messages
docker exec -it pulsar bin/pulsar-client consume \
  my-topic \
  -s test-sub \
  -n 0  # 0 = infinite
```

### Produce from CLI

```bash
# Produce messages
docker exec -it pulsar bin/pulsar-client produce \
  my-topic \
  -m "Hello from CLI"
```

## Configuration

### Client Configuration

```go
client, err := pulsar.NewClient(pulsar.ClientOptions{
    URL:              "pulsar://localhost:6650",
    OperationTimeout: 30 * time.Second,
    ConnectionTimeout: 10 * time.Second,
})
```

### Producer Configuration

```go
producer, err := client.CreateProducer(pulsar.ProducerOptions{
    Topic:                   "my-topic",
    BatchingMaxMessages:     100,
    BatchingMaxPublishDelay: 10 * time.Millisecond,
    CompressionType:         pulsar.LZ4,
    SendTimeout:            30 * time.Second,
})
```

### Consumer Configuration

```go
consumer, err := client.Subscribe(pulsar.ConsumerOptions{
    Topic:               "my-topic",
    SubscriptionName:    "my-sub",
    Type:                pulsar.Shared,
    SubscriptionInitialPosition: pulsar.SubscriptionPositionEarliest,
    NackRedeliveryDelay: 1 * time.Minute,
})
```

## Troubleshooting

### Issue: Cannot connect to Pulsar

**Error:** `connection refused` or `timeout`

**Solutions:**
```bash
# Verify Pulsar is running
docker-compose ps

# Check Pulsar startup logs
docker-compose logs pulsar | grep "messaging service is ready"

# Wait 30-60 seconds for Pulsar to fully start
docker-compose up -d && sleep 60
```

### Issue: Consumer not receiving messages

**Solutions:**
1. Ensure consumer is running BEFORE producer
2. Check topic name matches exactly
3. Verify acknowledgments are being sent
4. Try `SubscriptionPositionEarliest` to read from beginning:
   ```go
   SubscriptionInitialPosition: pulsar.SubscriptionPositionEarliest
   ```

### Issue: Messages stuck in subscription

**Symptoms:** Messages sent but not delivered

**Solutions:**
```bash
# Check subscription stats
docker exec -it pulsar bin/pulsar-admin topics stats \
  persistent://public/default/my-topic

# Look for backlog size
# Reset cursor to earliest
docker exec -it pulsar bin/pulsar-admin topics reset-cursor \
  persistent://public/default/my-topic \
  -s my-subscription \
  --time -1
```

### Issue: Port already in use

**Solutions:**
```bash
# Stop existing Pulsar
docker-compose down

# Check what's using the port
lsof -i :6650
lsof -i :8080
```

### Issue: Out of memory

**Symptoms:** Pulsar container crashes

**Solutions:**
Edit `docker-compose.yml` and increase memory:
```yaml
environment:
  PULSAR_MEM: "-Xms1g -Xmx1g -XX:MaxDirectMemorySize=512m"
```

## Advanced Features

### Multi-Tenancy

Organize topics hierarchically:

```
persistent://tenant/namespace/topic
```

Example:
```go
// Team A topics
producer1, _ := client.CreateProducer(pulsar.ProducerOptions{
    Topic: "persistent://team-a/analytics/events",
})

// Team B topics (isolated from Team A)
producer2, _ := client.CreateProducer(pulsar.ProducerOptions{
    Topic: "persistent://team-b/analytics/events",
})
```

### Message Properties

Add metadata to messages:

```go
producer.Send(context.Background(), &pulsar.ProducerMessage{
    Payload: []byte("message"),
    Properties: map[string]string{
        "user-id": "12345",
        "region":  "us-west",
    },
})
```

### Delayed Message Delivery

Schedule messages for future delivery:

```go
producer.Send(context.Background(), &pulsar.ProducerMessage{
    Payload:      []byte("delayed message"),
    DeliverAfter: 5 * time.Minute,  // Deliver in 5 minutes
})
```

### Dead Letter Queue

Handle failed messages:

```go
consumer, err := client.Subscribe(pulsar.ConsumerOptions{
    Topic:               "my-topic",
    SubscriptionName:    "my-sub",
    Type:                pulsar.Shared,
    DLQ: &pulsar.DLQPolicy{
        MaxDeliveries:    3,
        DeadLetterTopic: "my-topic-dlq",
    },
})
```

## Performance Tips

### For Producers:
- **Enable batching**: Combine multiple messages
- **Use compression**: LZ4 or Zstd
- **Async send**: Don't wait for each message acknowledgment
- **Tune batch size**: Balance latency vs throughput

### For Consumers:
- **Shared subscriptions**: Parallel processing
- **Receiver queue**: Buffer messages client-side
- **Batch acknowledgment**: Ack multiple messages at once
- **Negative ack wisely**: Don't create infinite retry loops

### General:
- **Use standalone for dev**: Full Pulsar cluster for production
- **Monitor**: Use Pulsar Manager or Prometheus
- **Tiered storage**: Offload old data to S3/GCS

## Pulsar vs Kafka

| Feature | Pulsar | Kafka |
|---------|--------|-------|
| **Architecture** | Layered (broker + storage) | Monolithic |
| **Scalability** | Independent scaling | Coupled scaling |
| **Multi-tenancy** | Built-in | Add-on |
| **Geo-replication** | Built-in | External tools |
| **Ecosystem** | Growing | Very mature |
| **Operations** | More complex | Complex |
| **Use Case** | Cloud-native, multi-tenant | Event streaming, simpler model |

## Next Steps

1. **Experiment**: Try different subscription types
2. **Multi-tenancy**: Create topics in different namespaces
3. **Properties**: Add metadata to messages
4. **DLQ**: Implement dead letter queue handling
5. **Compare**: Read [COMPARISON.md](../COMPARISON.md) for other options

## Additional Resources

- [Pulsar Documentation](https://pulsar.apache.org/docs/)
- [Pulsar Go Client](https://github.com/apache/pulsar-client-go)
- [Pulsar Architecture](https://pulsar.apache.org/docs/concepts-architecture-overview/)
- [Pulsar vs Kafka](https://pulsar.apache.org/blog/2021/01/22/pulsar-vs-kafka-part-1/)

---

**Cloud-native messaging!** Pulsar brings enterprise features like multi-tenancy and geo-replication to message streaming.

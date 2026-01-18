# NSQ Quick Start Guide

## What is NSQ?

NSQ is a **real-time distributed messaging platform** designed to operate at scale. It was created by bitly and is known for its simplicity, ease of deployment, and lack of single points of failure.

### Key Concepts

- **Producer**: Application that publishes messages to NSQ
- **Consumer**: Application that subscribes to and processes messages
- **Topic**: Stream of messages (e.g., "test", "events", "logs")
- **Channel**: Independent queue per consumer group (multiple channels can subscribe to one topic)
- **nsqd**: The daemon that receives, queues, and delivers messages
- **nsqlookupd**: Service discovery daemon that manages topology
- **nsqadmin**: Web UI for monitoring and administration

### When to Use NSQ

✅ **Use NSQ for:**
- Real-time distributed messaging at scale
- Simple distributed topology without complex setup
- Go applications (excellent Go support)
- At-least-once delivery guarantees
- Easy horizontal scaling

❌ **Don't use NSQ for:**
- Message ordering guarantees
- Complex routing or filtering
- Exactly-once delivery semantics
- Non-Go applications (limited client libraries)

## Architecture Overview

```
Producer → nsqd (topic) → Channel A → Consumer A
                       → Channel B → Consumer B
                       → Channel C → Consumer C
```

**Key Features:**
- **No single point of failure**: Distributed by design
- **Horizontal scaling**: Add more nsqd instances easily
- **Load balancing**: Messages distributed across consumers in a channel
- **Message durability**: Messages persisted to disk
- **Simple operations**: No ZooKeeper or complex coordination

## Setup Instructions

### 1. Start NSQ with Docker Compose

```bash
# Navigate to the NSQ directory
cd /path/to/kafka-test/nsq

# Start NSQ cluster (nsqlookupd, nsqd, nsqadmin)
docker-compose up -d

# Verify services are running
docker-compose ps
```

You should see:
- `nsqlookupd` - Running on port 4160, 4161
- `nsqd` - Running on port 4150, 4151
- `nsqadmin` - Running on port 4171

### 2. Access NSQ Admin UI

Open your browser and navigate to:
- **NSQ Admin**: http://localhost:4171

This provides:
- Real-time statistics
- Topic and channel monitoring
- Message counts and rates
- Node health status

## Running the Examples

### Terminal 1 - Start Consumer

```bash
# Navigate to NSQ directory
cd nsq

# Run consumer (it will wait for messages)
go run consumer.go
```

The consumer will:
- Connect to nsqlookupd at `localhost:4161`
- Subscribe to topic `test` via channel `test_channel`
- Wait for messages

### Terminal 2 - Run Producer

```bash
# In a new terminal, navigate to NSQ directory
cd nsq

# Run producer (sends messages)
go run producer.go
```

**Expected Output (Producer):**
```
Published message to NSQ
Published message to NSQ
...
```

**Expected Output (Consumer):**
```
Received message: [message content]
Received message: [message content]
...
```

## Understanding the Code

### Producer Code (producer.go)

```go
// 1. Create producer connected to nsqd
producer, err := nsq.NewProducer("localhost:4150", config)

// 2. Publish messages to a topic
err = producer.Publish("test", []byte("Hello NSQ!"))

// 3. Clean up
producer.Stop()
```

**Key Concepts:**
- **Direct Connection**: Producer connects directly to nsqd
- **Simple Publishing**: Just topic name and message body
- **Synchronous**: Publish() waits for acknowledgment
- **No Partitions**: NSQ doesn't have partition concept like Kafka

### Consumer Code (consumer.go)

```go
// 1. Create consumer
consumer, err := nsq.NewConsumer("test", "test_channel", config)

// 2. Add message handler
consumer.AddHandler(nsq.HandlerFunc(func(message *nsq.Message) error {
    fmt.Printf("Received: %s\n", string(message.Body))
    return nil  // Auto-finishes message (acknowledges)
}))

// 3. Connect to nsqlookupd for discovery
err = consumer.ConnectToNSQLookupd("localhost:4161")

// 4. Wait for messages
select {}  // Run forever
```

**Key Concepts:**
- **Handler Pattern**: Process messages with a handler function
- **Service Discovery**: Use nsqlookupd to find nsqd instances
- **Channels**: Each consumer creates an independent channel
- **Auto-finish**: Returning nil acknowledges the message

## NSQ Components Explained

### nsqd (Message Queue Daemon)

The core daemon that:
- Receives messages from producers
- Stores messages in memory and disk
- Delivers messages to consumers
- Handles message acknowledgments

**Ports:**
- `4150`: TCP port for producers/consumers
- `4151`: HTTP port for stats and admin

### nsqlookupd (Discovery Service)

Service discovery that:
- Tracks available nsqd instances
- Helps consumers find nsqd nodes
- Provides topology information

**Ports:**
- `4160`: TCP port for nsqd
- `4161`: HTTP port for consumers

### nsqadmin (Web UI)

Administration interface that:
- Shows real-time statistics
- Monitors topics and channels
- Displays message rates
- Manages topics/channels

**Access:** http://localhost:4171

## Common Operations

### View Topics

```bash
# Using nsqadmin HTTP API
curl http://localhost:4171/api/topics

# Or visit the web UI
open http://localhost:4171
```

### View Stats for a Topic

```bash
curl http://localhost:4151/stats?format=json
```

### Create a Topic

Topics are created automatically when you publish to them:

```bash
curl -X POST http://localhost:4151/topic/create?topic=new_topic
```

### Empty a Topic

```bash
curl -X POST http://localhost:4151/topic/empty?topic=test
```

### Delete a Topic

```bash
curl -X POST http://localhost:4151/topic/delete?topic=test
```

## Configuration

### Producer Configuration

```go
config := nsq.NewConfig()
config.MaxInFlight = 200           // Max unacknowledged messages
config.WriteTimeout = time.Second  // Timeout for writes
```

### Consumer Configuration

```go
config := nsq.NewConfig()
config.MaxInFlight = 200              // Max concurrent messages
config.MaxAttempts = 5                // Retry failed messages
config.RequeueDelay = time.Second     // Delay before retry
config.MaxBackoffDuration = 2 * time.Minute
```

## Troubleshooting

### Issue: Consumer not receiving messages

**Solutions:**
1. Ensure nsqlookupd is running and accessible
2. Verify topic name matches in producer and consumer
3. Check nsqd logs: `docker-compose logs nsqd`
4. Visit nsqadmin UI to verify messages are being published

### Issue: Messages being requeued repeatedly

**Symptoms:** Same message processed multiple times

**Solutions:**
1. Ensure handler returns `nil` on success
2. Return `error` only for transient failures
3. Check `MaxAttempts` configuration
4. Implement proper error handling

### Issue: Cannot connect to nsqlookupd

**Error:** `Failed to connect to nsqlookupd`

**Solutions:**
```bash
# Verify nsqlookupd is running
docker-compose ps

# Check logs
docker-compose logs nsqlookupd

# Test connectivity
curl http://localhost:4161/ping
```

### Issue: Port already in use

**Solutions:**
```bash
# Stop existing NSQ services
docker-compose down

# Check what's using the port
lsof -i :4150
lsof -i :4171
```

## Advanced Features

### Multiple Channels

Multiple channels create **independent queues** for different consumers:

```go
// Consumer 1: Analytics team
consumer1, _ := nsq.NewConsumer("events", "analytics", config)

// Consumer 2: Logging team
consumer2, _ := nsq.NewConsumer("events", "logging", config)

// Both receive ALL messages from "events" topic independently!
```

### Message Requeuing

Handle temporary failures by requeuing messages:

```go
consumer.AddHandler(nsq.HandlerFunc(func(m *nsq.Message) error {
    err := processMessage(m)
    if err != nil {
        // Requeue for retry
        m.Requeue(time.Second * 5)
        return err
    }
    return nil  // Success - message finished
}))
```

### In-Flight Messages

Control concurrent message processing:

```go
config := nsq.NewConfig()
config.MaxInFlight = 10  // Process up to 10 messages concurrently
```

## Performance Tips

### For Producers:
- **Batch publishing**: Use `MultiPublish()` for multiple messages
- **Connection pooling**: Reuse producer instances
- **Error handling**: Implement retry logic for transient failures

### For Consumers:
- **MaxInFlight**: Tune based on processing time
- **Handler efficiency**: Fast handlers = higher throughput
- **Parallelism**: Run multiple consumer instances

### For Deployment:
- **Multiple nsqd instances**: Spread load across nodes
- **SSD for disk queue**: Faster message persistence
- **Monitor nsqadmin**: Watch for backed-up channels

## Scaling NSQ

### Horizontal Scaling

1. **Add more nsqd instances:**
   ```bash
   # Run additional nsqd nodes
   docker run -d --name nsqd2 -p 4250:4150 nsqio/nsq \
     /nsqd --lookupd-tcp-address=nsqlookupd:4160
   ```

2. **Consumers auto-discover new nodes** via nsqlookupd

3. **Producers can round-robin** across nsqd instances

### Load Balancing

NSQ automatically load balances messages within a channel:
- Run multiple consumers with the same topic+channel
- Messages distributed evenly across consumers

## Comparison with Other Systems

**NSQ vs Kafka:**
- ✅ NSQ: Simpler ops, no ZooKeeper, easier to deploy
- ❌ NSQ: No message ordering, no replay capability
- ✅ Kafka: Message ordering, replay, richer ecosystem
- ❌ Kafka: More complex, requires ZooKeeper

**NSQ vs RabbitMQ:**
- ✅ NSQ: Better distributed architecture, easier scaling
- ❌ NSQ: Less flexible routing
- ✅ RabbitMQ: Rich routing features, more mature
- ❌ RabbitMQ: Harder to scale horizontally

## Next Steps

1. **Experiment**: Try multiple consumers on the same channel
2. **Multiple Channels**: Create different channels for different use cases
3. **Error Handling**: Implement retry logic and dead letter handling
4. **Production**: Learn about deployment, monitoring, and security
5. **Explore**: Check out the [COMPARISON.md](../COMPARISON.md) guide

## Additional Resources

- [NSQ Official Documentation](https://nsq.io/)
- [NSQ Design Document](https://nsq.io/overview/design.html)
- [NSQ Go Client](https://github.com/nsqio/go-nsq)
- [NSQ Deployment Guide](https://nsq.io/deployment/docker.html)

---

**Happy Messaging!** NSQ makes distributed messaging simple and reliable.

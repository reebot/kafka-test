# ActiveMQ Quick Start Guide

## What is Apache ActiveMQ?

Apache ActiveMQ is a **multi-protocol message broker** that supports JMS (Java Message Service) and multiple other protocols. It's a mature, enterprise-grade messaging system widely used in Java environments and legacy system integration.

### Key Concepts

- **Producer**: Application that sends messages to ActiveMQ
- **Consumer**: Application that receives messages from ActiveMQ
- **Queue**: Point-to-point messaging (one message to one consumer)
- **Topic**: Publish-subscribe messaging (one message to many consumers)
- **Broker**: ActiveMQ server that manages messages
- **Destination**: Either a queue or topic
- **STOMP**: Simple Text Oriented Messaging Protocol (used in these examples)

### When to Use ActiveMQ

✅ **Use ActiveMQ for:**
- Enterprise Java applications (JMS compatibility)
- Multiple protocol support (STOMP, AMQP, MQTT, OpenWire)
- Legacy system integration
- Cross-platform messaging
- XA transactions and distributed transactions
- Proven, battle-tested reliability

❌ **Don't use ActiveMQ for:**
- Very high throughput requirements
- Modern cloud-native applications (consider ActiveMQ Artemis or Pulsar)
- Active development (ActiveMQ Classic is in maintenance mode)
- Horizontal scaling (vertical scaling primarily)

## Architecture Overview

```
Producer → Broker (ActiveMQ) → Queue/Topic → Consumer
                                     ↓
                              (persisted to disk)
```

**Key Features:**
- **Multi-protocol**: Supports JMS, STOMP, AMQP, MQTT, OpenWire
- **Reliability**: Persistent storage and transactional messaging
- **Flexibility**: Both queue (point-to-point) and topic (pub/sub) patterns
- **Mature**: Proven in production for decades
- **Web Console**: Built-in management and monitoring UI

## Setup Instructions

### 1. Start ActiveMQ with Docker Compose

```bash
# Navigate to the ActiveMQ directory
cd /path/to/kafka-test/activemq

# Start ActiveMQ with web console
docker-compose up -d

# Verify services are running
docker-compose ps
```

You should see:
- `activemq` - Running on ports 61613 (STOMP), 8161 (Web Console)

### 2. Access ActiveMQ Web Console

Open your browser and navigate to:
- **Web Console**: http://localhost:8161
- **Admin Console**: http://localhost:8161/admin

**Login Credentials:**
- Username: `admin`
- Password: `admin`

The Web Console provides:
- **Queues and Topics**: View and manage destinations
- **Send & Browse Messages**: Test message flow
- **Monitoring**: Broker statistics, memory usage, connections
- **Subscribers**: View active consumers

## Running the Examples

### Terminal 1 - Start Consumer

```bash
# Navigate to ActiveMQ directory
cd activemq

# Run consumer (it will wait for messages)
go run consumer.go
```

**Output:**
```
Connected to ActiveMQ
Subscribed to queue: /queue/test
Waiting for messages... (Press Ctrl+C to exit)
```

### Terminal 2 - Run Producer

```bash
# In a new terminal, navigate to ActiveMQ directory
cd activemq

# Run producer (sends messages)
go run producer.go
```

**Expected Output (Producer):**
```
Connected to ActiveMQ
Message sent: Hello from ActiveMQ!
Disconnected from ActiveMQ
```

**Expected Output (Consumer):**
```
Received message: Hello from ActiveMQ!
```

## Understanding the Code

### Producer Code (producer.go)

```go
// 1. Connect to ActiveMQ via STOMP
conn, err := stomp.Dial("tcp", "localhost:61613")

// 2. Send message to a queue
err = conn.Send(
    "/queue/test",           // Destination (queue)
    "text/plain",            // Content type
    []byte("Hello ActiveMQ!"), // Message body
)

// 3. Disconnect
conn.Disconnect()
```

**Key Concepts:**
- **STOMP Protocol**: Text-based protocol, simpler than JMS
- **Destination**: `/queue/name` for queues, `/topic/name` for topics
- **Content Type**: Specify message format (text/plain, application/json, etc.)
- **Synchronous**: Send() waits for acknowledgment

### Consumer Code (consumer.go)

```go
// 1. Connect to ActiveMQ via STOMP
conn, err := stomp.Dial("tcp", "localhost:61613")

// 2. Subscribe to a queue
sub, err := conn.Subscribe(
    "/queue/test",      // Destination
    stomp.AckAuto,      // Auto-acknowledge mode
)

// 3. Receive messages
for {
    msg := <-sub.C  // Blocking receive
    fmt.Printf("Received: %s\n", msg.Body)
}

// 4. Unsubscribe and disconnect
sub.Unsubscribe()
conn.Disconnect()
```

**Key Concepts:**
- **Subscription**: Creates a channel that receives messages
- **Auto-ack**: Messages automatically acknowledged
- **Blocking**: `<-sub.C` waits for next message
- **Graceful Shutdown**: Unsubscribe before disconnecting

## Queue vs Topic

### Queue (Point-to-Point)

One message consumed by **one consumer** only.

```go
// Producer sends to queue
conn.Send("/queue/tasks", "text/plain", []byte("task data"))

// Multiple consumers compete for messages
consumer1.Subscribe("/queue/tasks", stomp.AckAuto)
consumer2.Subscribe("/queue/tasks", stomp.AckAuto)
// Each message goes to ONLY ONE consumer
```

**Use for:** Task distribution, load balancing

### Topic (Publish-Subscribe)

One message consumed by **all subscribers**.

```go
// Producer sends to topic
conn.Send("/topic/notifications", "text/plain", []byte("alert"))

// Multiple subscribers each receive the message
subscriber1.Subscribe("/topic/notifications", stomp.AckAuto)
subscriber2.Subscribe("/topic/notifications", stomp.AckAuto)
// Each subscriber receives the SAME message
```

**Use for:** Notifications, broadcasts, event distribution

## Common Operations

### View Queues and Topics

```bash
# Use the Web Console at http://localhost:8161/admin
# Or use REST API
curl -u admin:admin http://localhost:8161/api/jolokia/read/org.apache.activemq:type=Broker,brokerName=localhost/Queues
```

### Send Message via CLI

```bash
# Using curl to REST API (requires Jolokia)
curl -u admin:admin \
  -d "body=Test message" \
  -d "type=queue" \
  http://localhost:8161/api/message?destination=test
```

### Purge a Queue

```bash
# Using Web Console: Queues -> Select queue -> Purge
# Or via REST API
curl -u admin:admin \
  -X POST \
  http://localhost:8161/api/jolokia/exec/org.apache.activemq:type=Broker,brokerName=localhost,destinationType=Queue,destinationName=test/purge
```

### Check Broker Status

```bash
curl -u admin:admin http://localhost:8161/api/jolokia/read/org.apache.activemq:type=Broker,brokerName=localhost
```

## Configuration

### Connection Options

```go
// Basic connection
conn, err := stomp.Dial("tcp", "localhost:61613")

// With credentials
conn, err := stomp.Dial("tcp", "localhost:61613",
    stomp.ConnOpt.Login("admin", "admin"))

// With timeout
conn, err := stomp.Dial("tcp", "localhost:61613",
    stomp.ConnOpt.HeartBeat(10*time.Second, 10*time.Second))
```

### Send Options

```go
// Persistent message
err = conn.Send(
    "/queue/important",
    "text/plain",
    []byte("data"),
    stomp.SendOpt.Header("persistent", "true"),
)

// Message with custom headers
err = conn.Send(
    "/queue/test",
    "application/json",
    []byte(`{"key":"value"}`),
    stomp.SendOpt.Header("priority", "5"),
    stomp.SendOpt.Header("expires", "3600000"),
)
```

### Subscribe Options

```go
// Manual acknowledgment
sub, err := conn.Subscribe(
    "/queue/test",
    stomp.AckClient,  // Manual ack (not auto)
)

// Then acknowledge each message
msg := <-sub.C
// Process message...
conn.Ack(msg)
```

## Troubleshooting

### Issue: Cannot connect to ActiveMQ

**Error:** `dial tcp :61613: connect: connection refused`

**Solutions:**
```bash
# Verify ActiveMQ is running
docker-compose ps

# Check ActiveMQ logs
docker-compose logs activemq

# Wait for: "ActiveMQ ... started"
docker-compose logs activemq | grep "started"

# Test STOMP port
telnet localhost 61613
```

### Issue: Consumer not receiving messages

**Solutions:**
1. Verify consumer is subscribed to correct destination
2. Check queue vs topic (`/queue/name` vs `/topic/name`)
3. For topics: consumer must be subscribed BEFORE message is sent
4. Use Web Console to verify messages are in queue
5. Check subscription acknowledgment mode

### Issue: "Destination not found"

**Symptoms:** Messages not appearing in Web Console

**Solutions:**
- ActiveMQ auto-creates destinations by default
- Check destination name syntax: `/queue/name` or `/topic/name`
- Verify no typos in destination names
- Check broker configuration for auto-create settings

### Issue: Messages accumulating

**Symptoms:** Queue depth keeps growing

**Solutions:**
1. Check consumer is running and processing messages
2. Verify no errors in consumer
3. Check message acknowledgment mode
4. Add more consumers for load balancing
5. Use Web Console to inspect message details

### Issue: Port already in use

**Solutions:**
```bash
# Find what's using the port
lsof -i :61613
lsof -i :8161

# Stop existing ActiveMQ
docker-compose down
```

## Advanced Features

### Message Selectors

Filter messages at the broker:

```go
// Producer: Send messages with properties
conn.Send(
    "/queue/orders",
    "text/plain",
    []byte("order data"),
    stomp.SendOpt.Header("priority", "high"),
    stomp.SendOpt.Header("region", "us-west"),
)

// Consumer: Subscribe with selector
sub, err := conn.Subscribe(
    "/queue/orders",
    stomp.AckAuto,
    stomp.SubscribeOpt.Header("selector", "priority = 'high' AND region = 'us-west'"),
)
```

### Durable Subscriptions

For topics, maintain subscription across disconnects:

```go
// Create durable subscription
sub, err := conn.Subscribe(
    "/topic/events",
    stomp.AckAuto,
    stomp.SubscribeOpt.Header("id", "my-durable-sub"),
    stomp.SubscribeOpt.Header("persistent", "true"),
)
// Messages sent while disconnected will be delivered when reconnected
```

### Transactions

Group multiple operations:

```go
// Begin transaction
txID := "tx-001"
conn.Begin(txID)

// Send multiple messages in transaction
conn.Send("/queue/orders", "text/plain", []byte("order1"),
    stomp.SendOpt.Header("transaction", txID))
conn.Send("/queue/inventory", "text/plain", []byte("update1"),
    stomp.SendOpt.Header("transaction", txID))

// Commit (or abort)
conn.Commit(txID)
// conn.Abort(txID)
```

## Performance Tips

### For Producers:
- **Reuse connections** (expensive to create)
- **Non-persistent messages** for non-critical data (faster)
- **Batch operations** when possible
- **Connection pooling** for high-throughput scenarios

### For Consumers:
- **Manual ack** for reliability
- **Prefetch limit** to control memory usage
- **Multiple consumers** for load distribution
- **Async processing** for better throughput

### General:
- **Monitor memory usage** via Web Console
- **Use appropriate persistence** (persistent vs non-persistent)
- **Tune broker settings** (memory limits, store limits)
- **Clean up old messages** (set TTL or expiration)

## ActiveMQ Classic vs Artemis

**ActiveMQ Classic** (this repository):
- Original ActiveMQ
- Mature and stable
- Maintenance mode (fewer updates)
- Good for existing deployments

**ActiveMQ Artemis** (next generation):
- Complete rewrite
- Better performance and scalability
- Active development
- Recommended for new projects

## Comparison with Other Systems

**ActiveMQ vs RabbitMQ:**
- ✅ ActiveMQ: JMS support, multiple protocols
- ❌ ActiveMQ: Less active development
- ✅ RabbitMQ: More active, better tooling
- ❌ RabbitMQ: No JMS support

**ActiveMQ vs Kafka:**
- ✅ ActiveMQ: Traditional messaging, complex routing
- ❌ ActiveMQ: Lower throughput, no replay
- ✅ Kafka: High throughput, event streaming
- ❌ Kafka: Overkill for simple queues

## Next Steps

1. **Experiment**: Try both queues and topics
2. **Message Selectors**: Filter messages at broker level
3. **Transactions**: Implement atomic operations
4. **Durable Subscriptions**: Test topic persistence
5. **Compare**: Read [COMPARISON.md](../COMPARISON.md) for other options

## Additional Resources

- [ActiveMQ Documentation](https://activemq.apache.org/components/classic/)
- [STOMP Protocol](https://stomp.github.io/)
- [go-stomp Library](https://github.com/go-stomp/stomp)
- [ActiveMQ Artemis](https://activemq.apache.org/components/artemis/) (next generation)

---

**Enterprise messaging!** ActiveMQ provides reliable, multi-protocol messaging for enterprise and legacy systems.

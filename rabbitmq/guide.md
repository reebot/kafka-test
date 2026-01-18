# RabbitMQ Quick Start Guide

## What is RabbitMQ?

RabbitMQ is a **traditional message broker** that implements the Advanced Message Queuing Protocol (AMQP). It acts as a middleman for microservices, enabling reliable asynchronous communication through message queuing.

### Key Concepts

- **Producer**: Application that sends messages to RabbitMQ
- **Consumer**: Application that receives and processes messages
- **Queue**: Buffer that stores messages (e.g., "tasks", "emails", "orders")
- **Exchange**: Routing component that decides where messages go
- **Binding**: Rule that connects exchanges to queues
- **Routing Key**: Tag that helps exchange route messages
- **Virtual Host**: Logical grouping for isolation

### When to Use RabbitMQ

✅ **Use RabbitMQ for:**
- Task queues and background job processing
- Request-reply (RPC) patterns
- Work distribution across multiple workers
- Complex routing scenarios
- Guaranteed message delivery with acknowledgments
- Dead letter queues for failed messages

❌ **Don't use RabbitMQ for:**
- Very high throughput (> 100K messages/sec)
- Long-term message retention
- Event replay capabilities
- Event streaming (use Kafka instead)

## Architecture Overview

```
Producer → Exchange (routing) → Queue → Consumer
                                  ↓
                          (message deleted after ack)
```

**Key Features:**
- **Flexible routing**: Direct, topic, fanout, and headers exchanges
- **Reliability**: Message acknowledgments and persistence
- **Dead letter queues**: Handle failed messages automatically
- **Priority queues**: Process urgent messages first
- **Message TTL**: Expire old messages automatically

## Setup Instructions

### 1. Start RabbitMQ with Docker Compose

```bash
# Navigate to the RabbitMQ directory
cd /path/to/kafka-test/rabbitmq

# Start RabbitMQ with management plugin
docker-compose up -d

# Verify services are running
docker-compose ps
```

You should see:
- `rabbitmq` - Running on ports 5672 (AMQP), 15672 (Management UI)

### 2. Access RabbitMQ Management UI

Open your browser and navigate to:
- **Management UI**: http://localhost:15672

**Login Credentials:**
- Username: `user`
- Password: `password`

The Management UI provides:
- Queue and exchange monitoring
- Message rates and statistics
- Manual message publishing (for testing)
- Connection and channel tracking
- Virtual host management

## Running the Examples

### Terminal 1 - Start Consumer

```bash
# Navigate to RabbitMQ directory
cd rabbitmq

# Run consumer (it will wait for messages)
go run consumer.go
```

**Output:**
```
Connected to RabbitMQ
Waiting for messages... (Press Ctrl+C to exit)
```

### Terminal 2 - Run Producer

```bash
# In a new terminal, navigate to RabbitMQ directory
cd rabbitmq

# Run producer (sends messages)
go run producer.go
```

**Expected Output (Producer):**
```
Connected to RabbitMQ
Message sent: Hello World!
Connection closed
```

**Expected Output (Consumer):**
```
Received message: Hello World!
Received message: Hello World!
...
```

## Understanding the Code

### Producer Code (producer.go)

```go
// 1. Connect to RabbitMQ
conn, err := amqp.Dial("amqp://user:password@localhost:5672/")

// 2. Create a channel
ch, err := conn.Channel()

// 3. Declare a queue (creates if doesn't exist)
q, err := ch.QueueDeclare(
    "hello",  // Queue name
    false,    // Durable (survive broker restart)
    false,    // Auto-delete when unused
    false,    // Exclusive (only this connection)
    false,    // No-wait
    nil,      // Arguments
)

// 4. Publish a message
err = ch.Publish(
    "",       // Exchange (empty = default)
    q.Name,   // Routing key (queue name)
    false,    // Mandatory
    false,    // Immediate
    amqp.Publishing{
        ContentType: "text/plain",
        Body:        []byte("Hello World!"),
    },
)

// 5. Clean up
ch.Close()
conn.Close()
```

**Key Concepts:**
- **Connection**: TCP connection to RabbitMQ
- **Channel**: Virtual connection within a TCP connection
- **QueueDeclare**: Idempotent (safe to call multiple times)
- **Default Exchange**: Empty string "" uses direct exchange
- **Routing Key**: When using default exchange, it's the queue name

### Consumer Code (consumer.go)

```go
// 1. Connect to RabbitMQ
conn, err := amqp.Dial("amqp://user:password@localhost:5672/")

// 2. Create a channel
ch, err := conn.Channel()

// 3. Declare the same queue
q, err := ch.QueueDeclare("hello", false, false, false, false, nil)

// 4. Consume messages
msgs, err := ch.Consume(
    q.Name,   // Queue name
    "",       // Consumer tag
    true,     // Auto-ack (automatic acknowledgment)
    false,    // Exclusive
    false,    // No-local
    false,    // No-wait
    nil,      // Arguments
)

// 5. Process messages
for msg := range msgs {
    fmt.Printf("Received: %s\n", msg.Body)
}

// 6. Clean up
ch.Close()
conn.Close()
```

**Key Concepts:**
- **Consume**: Returns a Go channel of messages
- **Auto-ack**: Message automatically acknowledged (deleted from queue)
- **Manual ack**: Set auto-ack=false, then call `msg.Ack(false)`
- **Prefetch**: Control how many messages consumer receives at once

## Common Operations

### View Queues

```bash
# Using rabbitmqadmin (install first)
docker exec -it rabbitmq rabbitmqadmin list queues

# Or use Management UI at http://localhost:15672
```

### Create a Queue

```bash
docker exec -it rabbitmq rabbitmqadmin declare queue name=myqueue durable=true
```

### Publish a Message from CLI

```bash
docker exec -it rabbitmq rabbitmqadmin publish routing_key=hello payload="Test message"
```

### Get Messages from Queue

```bash
docker exec -it rabbitmq rabbitmqadmin get queue=hello ackmode=ack_requeue_false
```

### List Exchanges

```bash
docker exec -it rabbitmq rabbitmqadmin list exchanges
```

### Purge a Queue

```bash
docker exec -it rabbitmq rabbitmqadmin purge queue name=hello
```

## Configuration

### Connection String Format

```
amqp://username:password@host:port/vhost
```

Examples:
```go
// Local development
"amqp://user:password@localhost:5672/"

// With virtual host
"amqp://user:password@localhost:5672/myvhost"

// Production (TLS)
"amqps://user:password@production.rabbitmq.com:5671/"
```

### Channel Configuration

```go
// Set prefetch count (QoS)
err = ch.Qos(
    10,    // Prefetch count (max unacknowledged messages)
    0,     // Prefetch size
    false, // Global
)
```

### Queue Options

```go
q, err := ch.QueueDeclare(
    "tasks",           // Name
    true,              // Durable (survive restart)
    false,             // Auto-delete
    false,             // Exclusive
    false,             // No-wait
    amqp.Table{
        "x-message-ttl": 60000,  // 60 seconds TTL
        "x-max-length": 1000,    // Max 1000 messages
    },
)
```

## Troubleshooting

### Issue: Cannot connect to RabbitMQ

**Error:** `dial tcp :5672: connect: connection refused`

**Solutions:**
```bash
# Verify RabbitMQ is running
docker-compose ps

# Check RabbitMQ logs
docker-compose logs rabbitmq

# Wait for: "Server startup complete"
docker-compose logs rabbitmq | grep "startup complete"
```

### Issue: Consumer not receiving messages

**Solutions:**
1. Ensure consumer is running BEFORE producer
2. Verify queue name matches exactly
3. Check auto-ack setting
4. Use Management UI to verify messages in queue
5. Check for errors in consumer logs

### Issue: Messages accumulating in queue

**Symptoms:** Queue depth keeps growing

**Solutions:**
1. Check consumer is running and processing messages
2. Verify consumer isn't erroring out
3. Check prefetch count (Qos setting)
4. Add more consumers for parallel processing
5. Check message processing time

### Issue: "NOT_FOUND - no queue"

**Error:** Channel exception: NOT_FOUND

**Solutions:**
- Declare queue before consuming
- Ensure producer and consumer use same queue name
- Check for typos in queue name

### Issue: Port already in use

**Solutions:**
```bash
# Find what's using the port
lsof -i :5672
lsof -i :15672

# Stop existing RabbitMQ
docker-compose down
```

## Advanced Features

### Manual Acknowledgments

For reliable processing, use manual acks:

```go
// Consumer with manual ack
msgs, err := ch.Consume(
    q.Name,
    "",
    false,  // Auto-ack = FALSE (manual ack)
    false, false, false, nil,
)

for msg := range msgs {
    err := processMessage(msg.Body)
    if err != nil {
        // Reject and requeue
        msg.Nack(false, true)
    } else {
        // Acknowledge successful processing
        msg.Ack(false)
    }
}
```

### Dead Letter Exchange

Handle failed messages:

```go
// Declare queue with DLX
q, err := ch.QueueDeclare(
    "tasks",
    true, false, false, false,
    amqp.Table{
        "x-dead-letter-exchange": "failed-tasks-dlx",
        "x-max-delivery-count": 3,  // After 3 retries, send to DLX
    },
)
```

### Topic Exchange

Advanced routing with patterns:

```go
// Declare topic exchange
err = ch.ExchangeDeclare(
    "logs",    // Name
    "topic",   // Type
    true,      // Durable
    false, false, false, nil,
)

// Bind with routing pattern
err = ch.QueueBind(
    q.Name,           // Queue
    "kern.*",         // Routing key pattern
    "logs",           // Exchange
    false, nil,
)

// Publish with routing key
err = ch.Publish(
    "logs",           // Exchange
    "kern.critical",  // Routing key
    false, false,
    amqp.Publishing{Body: []byte("Critical kernel error")},
)
```

### Fanout Exchange

Broadcast to all queues:

```go
// Declare fanout exchange
err = ch.ExchangeDeclare("broadcasts", "fanout", true, false, false, false, nil)

// Multiple queues bind to same exchange
ch.QueueBind(queue1.Name, "", "broadcasts", false, nil)
ch.QueueBind(queue2.Name, "", "broadcasts", false, nil)

// Message goes to all bound queues
ch.Publish("broadcasts", "", false, false, amqp.Publishing{Body: []byte("Broadcast!")})
```

## Performance Tips

### For Producers:
- **Reuse connections and channels** (expensive to create)
- **Use publisher confirms** for reliability
- **Batch messages** when possible
- **Use persistent messages sparingly** (disk I/O overhead)

### For Consumers:
- **Prefetch count**: Tune based on processing time
- **Multiple consumers**: Scale horizontally
- **Manual acks**: More reliable than auto-ack
- **Connection pooling**: Reuse connections

### General:
- **Durable queues**: Only if you need persistence
- **Message persistence**: Only for critical messages
- **Monitoring**: Use Management UI or Prometheus
- **Resource limits**: Set memory and disk alarms

## Real-World Use Cases

### Task Queue

```go
// Producer (web server)
ch.Publish("", "email-queue", false, false,
    amqp.Publishing{Body: []byte(emailData)})

// Consumer (background worker)
for msg := range msgs {
    sendEmail(msg.Body)
    msg.Ack(false)
}
```

### RPC (Request-Reply)

```go
// Request
ch.Publish("", "rpc_queue", false, false,
    amqp.Publishing{
        ReplyTo:       replyQueue,
        CorrelationId: uuid.New(),
        Body:          []byte("compute_fibonacci(30)"),
    })

// Response
ch.Publish("", msg.ReplyTo, false, false,
    amqp.Publishing{
        CorrelationId: msg.CorrelationId,
        Body:          []byte(result),
    })
```

## Comparison with Other Systems

**RabbitMQ vs Kafka:**
- ✅ RabbitMQ: Better for task queues, complex routing
- ❌ RabbitMQ: Lower throughput, no replay
- ✅ Kafka: Higher throughput, message replay
- ❌ Kafka: More complex, overkill for simple queues

**RabbitMQ vs Redis:**
- ✅ RabbitMQ: Reliable delivery, acknowledgments
- ❌ RabbitMQ: Higher latency, more complex
- ✅ Redis: Much faster, simpler
- ❌ Redis: No reliability, fire-and-forget only

## Next Steps

1. **Experiment**: Try different exchange types (topic, fanout)
2. **Manual Acks**: Implement reliable message processing
3. **Dead Letter Queues**: Handle failed messages
4. **Multiple Consumers**: Scale processing horizontally
5. **Compare**: Read [COMPARISON.md](../COMPARISON.md) for other options

## Additional Resources

- [RabbitMQ Tutorials](https://www.rabbitmq.com/getstarted.html)
- [RabbitMQ AMQP Go Client](https://github.com/streadway/amqp)
- [RabbitMQ Best Practices](https://www.rabbitmq.com/best-practices.html)
- [RabbitMQ Management](https://www.rabbitmq.com/management.html)

---

**Perfect for task queues!** RabbitMQ makes asynchronous work distribution reliable and straightforward.

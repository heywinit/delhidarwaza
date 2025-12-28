# Delhi Darwaza

## Phase 0: Foundation & Setup

- [x] Project structure
- [x] Basic Elixir setup
- [ ] Testing framework setup
- [ ] Logging infrastructure

## Phase 1: Core Data Structures

### 1.1 Order Types

- [ ] Define `Order` struct (id, user_id, symbol, side, type, price, quantity, status, timestamp)
- [ ] Order side enum (Buy/Sell)
- [ ] Order type enum (Market, Limit, Stop, Stop-Limit)
- [ ] Order status enum (Pending, Active, Filled, PartiallyFilled, Cancelled, Rejected)

### 1.2 Order Book

- [ ] `OrderBook` struct (bids, asks, symbol)
- [ ] Price-time priority queue for bids (max-heap)
- [ ] Price-time priority queue for asks (min-heap)
- [ ] Order lookup map (order_id -> order)

### 1.3 Trade & Market Data

- [ ] `Trade` struct (id, buy_order_id, sell_order_id, price, quantity, timestamp)
- [ ] `Ticker` struct (symbol, last_price, volume_24h, high_24h, low_24h)
- [ ] `OrderBookSnapshot` struct (bids, asks, timestamp)

### 1.4 User & Account

- [ ] `User` struct (id, username, email, created_at)
- [ ] `Account` struct (user_id, balances map[symbol]balance)
- [ ] `Balance` struct (available, locked, total)

## Phase 2: Order Matching Engine

### 2.1 Basic Matching Logic

- [ ] Limit order matching algorithm
- [ ] Price-time priority matching
- [ ] Partial fill handling
- [ ] Full fill handling
- [ ] Order book update after match

### 2.2 Order Types Implementation

- [ ] Market order execution
- [ ] Limit order placement
- [ ] Stop order logic
- [ ] Stop-limit order logic

### 2.3 Trade Execution

- [ ] Trade creation on match
- [ ] Balance updates (deduct from locked, add to available)
- [ ] Order status updates
- [ ] Trade history recording

## Phase 3: Order Management

### 3.1 Order Placement

- [ ] Order validation (sufficient balance, valid price/quantity)
- [ ] Order insertion into order book
- [ ] Balance locking (lock funds for buy/sell)
- [ ] Order ID generation

### 3.2 Order Cancellation

- [ ] Order lookup and cancellation
- [ ] Balance unlocking
- [ ] Order book removal
- [ ] Status update

### 3.3 Order Modification

- [ ] Order amendment (price/quantity changes)
- [ ] Re-insertion into order book with new priority

## Phase 4: User & Account Management

### 4.1 User Operations

- [ ] User registration
- [ ] User authentication (basic)
- [ ] User lookup

### 4.2 Account Operations

- [ ] Account creation
- [ ] Balance queries
- [ ] Deposit handling
- [ ] Withdrawal handling (basic validation)

### 4.3 Portfolio Management

- [ ] Portfolio calculation (total value in base currency)
- [ ] Position tracking
- [ ] PnL calculation

## Phase 5: API Layer

### 5.1 HTTP Server

- [ ] HTTP server setup
- [ ] Route definitions
- [ ] Request/response handling
- [ ] JSON serialization/deserialization

### 5.2 REST API Endpoints

- [ ] `POST /api/orders` - Place order
- [ ] `GET /api/orders/:id` - Get order status
- [ ] `DELETE /api/orders/:id` - Cancel order
- [ ] `GET /api/orders` - List user orders
- [ ] `GET /api/trades` - List user trades
- [ ] `GET /api/balance` - Get account balance
- [ ] `GET /api/orderbook/:symbol` - Get order book
- [ ] `GET /api/ticker/:symbol` - Get ticker data

### 5.3 WebSocket Support (Optional)

- [ ] WebSocket server setup
- [ ] Real-time order book updates
- [ ] Real-time trade feed
- [ ] User order updates

## Phase 6: Persistence

### 6.1 Data Storage

- [ ] Choose storage backend
- [ ] Order persistence
- [ ] Trade history persistence
- [ ] User/account persistence
- [ ] Balance persistence

### 6.2 Data Recovery

- [ ] Order book reconstruction on startup
- [ ] State recovery from persisted data
- [ ] Transaction logging (optional)

## Phase 7: Security & Validation

### 7.1 Input Validation

- [ ] Order parameter validation
- [ ] Price/quantity bounds checking
- [ ] Symbol validation
- [ ] Rate limiting (basic)

### 7.2 Error Handling

- [ ] Comprehensive error types
- [ ] Error propagation
- [ ] User-friendly error messages

## Phase 8: Testing & Quality

### 8.1 Unit Tests

- [ ] Order matching engine tests
- [ ] Order book tests
- [ ] Balance calculation tests
- [ ] Order validation tests

### 8.2 Integration Tests

- [ ] End-to-end order flow tests
- [ ] API endpoint tests
- [ ] Concurrent order handling tests

### 8.3 Performance Tests

- [ ] Order throughput benchmarks
- [ ] Latency measurements
- [ ] Memory usage profiling

## Phase 9: Advanced Features

### 9.1 Market Data

- [ ] 24h statistics calculation
- [ ] OHLCV (candlestick) data
- [ ] Order book depth levels
- [ ] Trade history pagination

### 9.2 Order Features

- [ ] Iceberg orders
- [ ] Time-in-force options (GTC, IOC, FOK)
- [ ] Order expiration
- [ ] Post-only orders

### 9.3 Exchange Features

- [ ] Multiple trading pairs
- [ ] Fee calculation
- [ ] Maker/taker fee differentiation
- [ ] Trading rules engine

## Phase 10: Optimization & Production

### 10.1 Performance

- [ ] Order book optimization (data structures)
- [ ] Memory pooling
- [ ] Lock-free data structures (if needed)
- [ ] Concurrent order processing

### 10.2 Monitoring

- [ ] Logging infrastructure
- [ ] Metrics collection
- [ ] Health check endpoints
- [ ] Performance monitoring

### 10.3 Documentation

- [ ] API documentation
- [ ] Architecture documentation
- [ ] Deployment guide
- [ ] Developer guide

## Milestones

1. **MVP (Minimum Viable Product)**: Phases 1-3

   - Basic order matching
   - Single trading pair
   - In-memory storage

2. **Beta**: Phases 1-5

   - REST API
   - User management
   - Basic persistence

3. **v1.0**: Phases 1-8

   - Full feature set
   - Tested and documented
   - Production-ready

4. **v2.0+**: Phases 9-10
   - Advanced features
   - Optimized performance
   - Production hardened

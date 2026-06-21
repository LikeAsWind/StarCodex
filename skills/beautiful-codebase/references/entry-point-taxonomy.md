# Entry-Point Taxonomy · 跨语言入口分类

> **何时读**：Phase 1 Discover 准备 Section 05 数据时（`codebase-brief.sh` 已经做了
> 一次粗糙正则计数，可以照本文件读）；Phase 4 Section 05 Step A SubAgent 开工时
> 详细对照检测规则。

Section 05 的核心是把目标项目的所有"从外部进入业务的口"识别出来并画成 mermaid
`flowchart TD`。本文档定义 **9 种角色 × 5+ 种语言**的检测规则，以及角色 → mermaid
class 映射、上限规则、异步边规则。

**反幻觉绑定**：每个节点 + 每条边都必须出现在 `NN-evidence.md` 里；Claim Audit
Reviewer 在 Section 05 每图采样 3 条边重新核对。**禁止**"这种代码通常长这样"的填空。

## 1 · 9 种角色（双语标签）

| # | 双语标签 | 它在系统里做什么 |
|---|---|---|
| 1 | **控制器方法 (Controller)** | HTTP / RPC 入口；外部 client 调用 |
| 2 | **定时任务 (Scheduled job)** | cron / scheduler 周期触发的任务 |
| 3 | **消息消费者 (Message consumer)** | 从 MQ / event bus 拉取 / 订阅消息触发 |
| 4 | **初始化加载 (Init loader)** | 应用启动 / 模块加载时一次性执行（bootstrapping） |
| 5 | **CLI 命令 (CLI entry)** | 命令行子命令 / argparse / cobra 子命令 |
| 6 | **事件监听器 (Event listener)** | 内部 event bus / 进程内事件触发 |
| 7 | **中间件 (Middleware)** | HTTP 请求 / RPC 调用链上的横切处理 |
| 8 | **Webhook** | 第三方系统按外部 URL POST 的入口 |
| 9 | **WebSocket / SSE** | 长连接 / 流式推送 / 双工通信入口 |

**标签写法约定**：mermaid 节点 / 流程图 / 表格里**始终用双语标签**，例如：
`控制器方法 (Controller) · UserController.create · src/controllers/user.go:42`。

## 2 · 检测规则 · codegraph 层（tier = codegraph-indexed）

```bash
# 通用形态
codegraph query <annotation> --json | jq '.[] | {symbol, file, line}'
```

| 角色 | 推荐查询 |
|---|---|
| Controller | `codegraph query "@RestController"` · `@Controller` · `@RequestMapping` · `@GetMapping` · `@PostMapping` · `@RoutePrefix` · `@router` |
| Scheduled job | `codegraph query "@Scheduled"` · `@Cron` · `celery.task` · `apscheduler.scheduled_job` |
| Message consumer | `codegraph query "@KafkaListener"` · `@RabbitListener` · `@SqsListener` · `@MessageMapping` · `@EventBridgeListener` |
| Init loader | `codegraph query "@PostConstruct"` · `InitializingBean.afterPropertiesSet` · `app.lifespan` · `register_startup_handler` |
| CLI entry | `codegraph query "cobra.Command"` · `click.command` · `argparse.ArgumentParser` · `commander.Command` |
| Event listener | `codegraph query "@EventListener"` · `EventBus.subscribe` · `emitter.on` |
| Middleware | `codegraph query "Middleware"` · `app.use` · `HandlerInterceptor` · `MiddlewareMixin` |
| Webhook | `codegraph query "webhook"` + URL pattern `/hooks/` |
| WebSocket / SSE | `codegraph query "WebSocket"` · `@ServerEndpoint` · `socket.on` · `EventSource` · `SSE` |

codegraph 模式下还可以用 `codegraph callers <symbol>` / `codegraph callees <symbol>`
追踪入口往下的 N 跳，构造 flowchart 的边。

## 3 · 检测规则 · rg 层（tier = rg）

每条规则按语言分组。`bc_query_text` 调用底层 `rg -n --no-heading`，输出 JSONL，主
Agent / SubAgent 再合并去重。

### 3.1 Controller

| 语言 | 正则 |
|---|---|
| Java / Kotlin / Spring | `@(RestController\|Controller\|GetMapping\|PostMapping\|PutMapping\|DeleteMapping\|PatchMapping\|RequestMapping)\b` |
| Python (Flask / FastAPI / Django) | `@(app\|router)\.(get\|post\|put\|delete\|patch)\(` · `class[[:space:]]+\w+View\b` · `path\([^)]*,\s*\w+View` |
| Go (Gin / Echo / chi) | `func[[:space:]]+\w+\.\w+\(.*\*?gin\.Context` · `r\.(GET\|POST\|PUT\|DELETE)\(` · `mux\.HandleFunc\(` |
| TS / JS (Express / Nest / Koa) | `(app\|router)\.(get\|post\|put\|delete\|patch)\(['"]` · `@(Controller\|Get\|Post\|Put\|Delete)\(` |
| Rust (Axum / Actix) | `\.route\(.*,[[:space:]]*get\\(\|post\\(\|put\\(` · `#\[get\(` · `#\[post\(` |
| C# (ASP.NET) | `\[Http(Get\|Post\|Put\|Delete)\]` · `\[Route\(` · `class[[:space:]]+\w+Controller[[:space:]]*:` |

### 3.2 Scheduled job

| 语言 | 正则 |
|---|---|
| Java | `@Scheduled\b` · `new[[:space:]]+Timer\(` · `ScheduledExecutorService` |
| Python | `@(celery\.)?task\b` · `@scheduled_job\b` · `@apscheduler\.` · `@cron\b` |
| Go | `cron\.New\(\)\|c\.AddFunc\(\|robfig/cron` |
| TS / JS | `node-cron\b\|setInterval\(.*\b\d` · `@Cron\(` · `Bull\b` · `BullMQ\b` |
| Rust | `tokio::time::interval\b` · `cron::Schedule` |
| C# | `BackgroundService\b` · `IHostedService\b` · `RecurringJob\b` |

### 3.3 Message consumer

| 语言 | 正则 |
|---|---|
| Java | `@KafkaListener\b` · `@RabbitListener\b` · `@SqsListener\b` · `@JmsListener\b` |
| Python | `consumer\.subscribe\(` · `@app\.task\b` · `kombu\.Consumer\b` · `aiokafka\.AIOKafkaConsumer` |
| Go | `consumer\.Consume\(` · `kafka\.NewReader\(` · `nsq\.NewConsumer\b` · `sarama\.NewConsumer` |
| TS / JS | `consumer\.run\(` · `@MessagePattern\(` · `BullMQ\.Worker\b` · `kafkajs\.Consumer` |
| Rust | `rdkafka::consumer::Consumer\b` · `lapin::Consumer` |

### 3.4 Init loader

| 语言 | 正则 |
|---|---|
| Java | `@PostConstruct\b` · `InitializingBean\b` · `ApplicationRunner\b` · `CommandLineRunner\b` |
| Python | `@app\.on_event\(['"]startup` · `with[[:space:]]+app\.lifespan\b` · `if __name__ == ['"]__main__['"]\s*:` |
| Go | `func[[:space:]]+init\(\)` · `func[[:space:]]+main\(\)` |
| TS / JS | `app\.ready\b` · `onModuleInit\b` · `bootstrap\(\)` |
| Rust | `fn[[:space:]]+main\(\)\|#\[tokio::main\]` |

### 3.5 CLI entry

| 语言 | 正则 |
|---|---|
| Java | `picocli\.CommandLine\b` · `args4j\b` · `JCommander\b` |
| Python | `argparse\.ArgumentParser\(` · `@click\.command\(` · `typer\.Typer\(` |
| Go | `cobra\.Command\{` · `urfave/cli\b` · `flag\.NewFlagSet\b` |
| TS / JS | `commander\.Command\b` · `yargs\b` · `oclif\.Command\b` |
| Rust | `clap::Parser\b` · `structopt\b` |

### 3.6 Event listener

| 语言 | 正则 |
|---|---|
| Java | `@EventListener\b` · `ApplicationListener\b` |
| Python | `blinker\.signal\b` · `dispatcher\.connect\b` · `pyee\b` |
| Go | `eventbus\.Subscribe\(` · `pubsub\.NewSubscription\(` |
| TS / JS | `emitter\.on\(['"][a-z]` · `EventEmitter\b` · `@OnEvent\(` |
| Rust | `EventEmitter\b` · `tokio::sync::broadcast` |

### 3.7 Middleware

| 语言 | 正则 |
|---|---|
| Java | `class[[:space:]]+\w*Filter\b` · `OncePerRequestFilter\b` · `HandlerInterceptor\b` |
| Python | `class[[:space:]]+\w+Middleware\b` · `class[[:space:]]+\w+\(MiddlewareMixin\)` · `middleware\b` |
| Go | `func[[:space:]]+\w*Middleware\(` · `gin\.HandlerFunc\b` · `func\(http\.Handler\)[[:space:]]+http\.Handler\b` |
| TS / JS | `app\.use\(` · `class[[:space:]]+\w+Middleware\b` · `@Injectable\(\)[[:space:]]+class[[:space:]]+\w+Middleware` |
| Rust | `Tower::ServiceBuilder\b` · `Layer<` |

### 3.8 Webhook

| 语言 | 正则（通用） |
|---|---|
| 任意 | `/hooks?/\b\|/webhook[s]?/\b` · `WebhookHandler\b` · `verify_signature\b` · `X-Hub-Signature\b` |

### 3.9 WebSocket / SSE

| 语言 | 正则 |
|---|---|
| Java | `@ServerEndpoint\b` · `WebSocketHandler\b` · `STOMP\b` |
| Python | `WebSocketRoute\b` · `websockets\.serve\b` · `EventSourceResponse\b` · `StreamingHttpResponse\b` |
| Go | `gorilla/websocket\b` · `nhooyr\.io/websocket\b` · `gws\b` |
| TS / JS | `socket\.io\b` · `ws\b\.Server\b` · `new EventSource\(` · `WebSocket\b` |
| Rust | `axum::extract::WebSocketUpgrade\b` · `tungstenite\b` |

## 4 · 检测规则 · grep 层（最小退化）

仅当 rg 不可用。精度大幅下降，但**角色映射保持一致**——我们仍用相同的 9 类，
只是检测线索退化为关键字而非正则：

| 角色 | grep 关键字（任一命中即认） |
|---|---|
| Controller        | `RestController` `Controller` `app.get(` `app.post(` `r.GET(` `@Get` `@Post` |
| Scheduled job     | `@Scheduled` `cron` `celery` `setInterval` `scheduler` |
| Message consumer  | `KafkaListener` `RabbitListener` `SqsListener` `consumer.subscribe` `consumer.run` |
| Init loader       | `PostConstruct` `func main()` `if __name__` `app.ready` `onModuleInit` |
| CLI entry         | `cobra.Command` `argparse` `click.command` `commander.Command` `clap::Parser` |
| Event listener    | `EventListener` `emitter.on(` `dispatcher.connect` |
| Middleware        | `Middleware` `Filter` `HandlerInterceptor` `app.use(` |
| Webhook           | `/webhook` `/hooks/` `WebhookHandler` |
| WebSocket / SSE   | `WebSocket` `socket.on(` `EventSource` `STOMP` |

每个 grep 命中给一个 `degraded: true` 标记（lib/query.sh 的 `bc_query_text` 在
grep 层已经这么做），Section 05 SubAgent 在 evidence.md 里要保留这个标签，最终
Section 头部加 caveat："工具 tier = grep，本节入口识别精度有限，可能漏报。"

## 5 · 角色 → mermaid class 映射

mermaid `flowchart TD` 节点的 `:::class` 取自 `theme-profiles/terminal.md` §4.3，
确保 5 种状态色和 1 种 business 色复用。

| 角色 | mermaid class | 颜色取自 terminal 主题 |
|---|---|---|
| Controller       | `:::controller` | `--ra-status-blue` |
| Scheduled job    | `:::middleware` | `--ra-keyword` |
| Message consumer | `:::consumer`   | `--ra-status-green` |
| Init loader      | `:::middleware` | `--ra-keyword` |
| CLI entry        | `:::controller` | `--ra-status-blue` |
| Event listener   | `:::consumer`   | `--ra-status-green` |
| Middleware       | `:::middleware` | `--ra-keyword` |
| Webhook          | `:::risk`       | `--ra-risk-red`（提醒：外部入口需 verify） |
| WebSocket / SSE  | `:::consumer`   | `--ra-status-green` |

业务实体 / 业务标签（subgraph）用 `:::business`，取自 `--ra-warn-amber`（避免与状态
色撞），确保 "技术节点 vs 业务标签" 视觉分层。

## 6 · 上限与排序规则

- **每类 ≤ 12 个 flowchart**——9 类 × 12 ≈ ~100 张图上限。超出列入"Other Entry Points"
  表格（仅 name + 一句概括 + file:line）。
- **排序优先级**：
  1. **调用深度**（callers/callees 跳数总和）—— 越深越关键。
  2. **跨模块边数** —— 跨越越多模块的入口越值得画成图。
  3. **按文件名 / 符号名字典序** —— tie-breaker。
- **用户覆盖**：Checkpoint 1 自由文本里可以说 "Section 05 上限改成 20 / 类" 或者
  "Controllers 全列出，其它角色只列 top 3"。主 Agent 把覆盖写进 plan.md Brief 段，
  Phase 4 Section 05 SubAgent 必读。

## 7 · 异步边的标注规则

flowchart 节点 + 边的语义：

- **同步调用** → 实线 `-->`，标签可省。
- **异步调用 / 后台触发** → 虚线 `-.->`，**必须**带 edge label 注明触发方式：
  - `by cron` —— 定时任务触发。
  - `on event` —— 事件总线触发。
  - `async dispatch` —— 主线程 fire-and-forget。
  - `via webhook` —— 外部 callback。
  - `via queue` —— 进程间 / 跨服务消息队列。
- **跨进程 / 跨服务调用** → 在边上注 `[cross-service: gRPC]` 或类似，**额外**用一条
  注释解释（在 Section 05 的 prose 里）。

mermaid 示例：

```mermaid
flowchart TD
  subgraph 业务: 订单结算
    api[控制器方法 (Controller)<br/>OrderController.checkout<br/>src/api/order.go:42]:::controller
    svc[OrderService.settle<br/>src/svc/order.go:88]
    pay[消息消费者 (Message consumer)<br/>PaymentConsumer.onPaid<br/>src/mq/payment.go:21]:::consumer
    api --> svc
    svc -.->|via queue: payment.events| pay
  end
  classDef controller fill:#0c2d4d,stroke:#1f6feb,color:#cdd9e5
  classDef consumer   fill:#0d2e1e,stroke:#2ea043,color:#cdd9e5
```

## 8 · 反幻觉绑定（Section 05 专用）

- **每个 mermaid 节点**——`角色 / 类·方法 / file:line`——的三段都必须能在 `NN-evidence.md`
  找到 verbatim 对应。`file:line` 是反查锚点。
- **每条边**——同步或异步——必须来自：
  - codegraph `callers` / `callees` 输出，或
  - rg/grep 的"调用名"命中（必须在 evidence.md 列出 verbatim），或
  - 配置文件 / 注解里的显式声明（如 `@Topics("payment.events")`）。
- **禁止**：基于"这类系统通常长这样"的填空节点；基于"我猜下游应该有"的虚边；
  跨技术栈猜测（例如根据 controller 名字猜 service 名字而不查 callers）。

Claim Audit Reviewer 在 Section 05 验收时，每图随机采样 3 条边，对每条边追溯到
`NN-evidence.md` 的具体行；找不到 verbatim 对应即 fail。fail 后主 Agent 修改对应
flowchart（删边或加上 evidence），不能"重写说服一下"。

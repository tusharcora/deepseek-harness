# Crew 插件：计划

[English](PLAN.md) | 中文

状态：草稿，等待批准。尚未构建任何内容。

## 共同约定

- 每个插件都是位于 `packages/experimental/crew-<name>` 的包，命名为 `@deepseek-ai/dsh-crew-<name>`，列入 `EXPERIMENTAL_PACKAGE_NAME_EXCEPTIONS`，版本与相邻包保持一致。每个包都有按仓库章节布局编写的 `README.md`、`locale/en.json`、`src/`、`tests/` 以及 `"license": "MIT"`。带配置行的插件附带 `cordis.patch.yml` 和 `icon.svg`，并像 `personalized-recommendations` 一样声明 `dsh.bundle`，这样 `plugin_manager` 可以单独安装它。
- 客户端 UI 文案来自有类型的 `locales.ts` 词典，并经由 `ctx.locale` 和 `t` 输出。CSS 模块只使用 `--dsw-alias-*` 和圆角 token。主按钮使用 `dsh-client-ui-primitives` 中跟随 brand-primary 的 `Button`。DeepSeek 蓝只作为点缀色出现。
- 测试：Host 端为 `*.spec.ts`，浏览器端为 `*.client.spec.tsx`，风格与各参照包一致。
- 每完成一个插件：运行它的测试和 `pnpm run build:artifacts`，用 `plugin_manager` 安装，在 http://127.0.0.1:3080 上检查，然后报告哪些可用、哪些不可用。
- 工作在分支上进行。你同意之前不提交任何内容。
- 没有点击就不会发送、发布、购买、删除、合并或预订任何东西。每个此类操作都是一种 `ctx.actionCards` 卡片，其处理函数只在用户点击触发的 Remote `act()` 中运行，模型永远拿不到直接执行该操作的工具。
- 凭据只通过 `ctx.credentials` 引用和 `ctx.authorization` 流程传递。任何文件都不保存密钥。
- 每个价格、评分或日期都显示其 `source` 和 `fetchedAt`。UI 中的示例数据标注为“示例数据”。

## 1. crew-faces

- 接缝：无，因为它是客户端库。它导出 `CrewFace({ agentId, mood: 'idle'|'working'|'needs-you', size, label })` 和纯函数 `faceGeometry(agentId, mood)`。
- 几何严格遵循规格：四种身体、每种身体的脸部圆形，以及两只在给定偏移和旋转下 `rx = w/2` 的药丸形眼睛。在 “working” 情绪下，两只眼睛都向右上方移动。
- 身体和颜色来自智能体 id 的稳定哈希。眼睛为 `#17181A`，身体为 `#0B0B0C` 时为白色。没有背景形状。眨眼是每隔几秒一次的 CSS `scaleY` 关键帧，按 id 错开，在 `prefers-reduced-motion` 下关闭。SVG 带有 `role="img"` 和 `aria-label`。
- 测试：每种身体下两只眼睛的精确中心、宽度、高度和旋转；同一 id 总是得到同一张脸；眼睛颜色规则；working 时的偏移；aria 标签；减弱动画。

## 2. crew-agents

- 接缝：
  - `cordis.patch.yml` 中六个 `dsh-agent-preset` 行：`crew-mail`、`crew-chat`、`crew-code`、`crew-research`、`crew-life` 和 `crew-chief`。每个都有一个 `dsh-persona` 和自己的工具行。
  - 幕僚长挂载 `provider: spawn`、`allowedAgentPresets: [crew-*]` 的 `dsh-tool-subagent`，以及 `dsh-agent-team` 和 `dsh-tool-agent-team`。
  - 一个 Host 服务 `ctx.crew`，带有 `@Remote` 名册流，提供每个智能体的 id、预设、名称和状态。它的客户端部分把这个可观察对象共享给其他 crew 插件。
- 状态：
  - **working**：有一个打开的轮次，由 `turnBoundaryOf` 读取。
  - **needs you**：该 Session 有未开始的操作卡片或未回答的 `userQuestions` 条目。
  - **idle**：其他所有情况。
- 连接账户之前的工具：
  - Mail：web 和只读 fs。
  - Chat：web。
  - Code：bash、fs、lsp 和 forge。
  - Research：web。
  - Life：schedule 和 web。

  Gmail、Slack 和 Telegram 工具等到“真实账户”那一步再加。
- 测试：六个预设都能加载并通过校验；幕僚长拒绝委派给白名单之外的预设；状态推导覆盖 working、needs-you 和 idle；名册 Remote 做了访问检查。

## 3. crew-stock-chart

- 接缝：
  - `ctx.tools` 上的 `ui_stock_chart({symbol, range})` 工具。其结果元数据携带 `{symbol, range, series[], source, fetchedAt}`。
  - 一个 `@Remote` `quote(symbol, range)`，卡片用它切换区间和刷新，两者都不需要模型。
  - 一个以 `ui_stock_chart` 为键的 `tool.call.toolview` 行。
  - 一张 ui-schedule 风格的 `conversation.chat.turnTail` 卡片。
- 卡片：价格、涨跌、1D/5D/1M/6M/1Y 按钮、折线/K 线切换和悬停十字线读数，全部用 SVG 绘制，不新增依赖。刷新间隔和数据源是配置字段。刷新失败时，卡片保留最后一次成功的序列，并显示“截至 <fetchedAt>”。
- 测试：数据源解析；工具结果的字段；区间切换和图表切换不调用模型；十字线读数；刷新失败时保留旧数据及其时间；toolview 各阶段。

## 4. crew-desktop

- 接缝：`ctx.sidebarRightTabs.register({ kind: 'crew-desktop' })`，以及 `sidebar.right.pane.tab` 和 `.title` 席位。这与 ui-sidebar-terminal 和 ui-sidebar-browser 使用的路径相同。
- v1 画面：来自该 Session 电脑使用工具结果的最新截图，经由 Gateway `loadImage` 加载。`ctx.computerUse` 没有通用的截图 API，所以它在每次智能体操作后更新一次，而不是连续的画面流。
- 控制：
  - **暂停**通过 Session 控制器中断智能体当前的轮次。
  - **接管**先暂停，然后显示“由你控制”状态，直到你恢复。
  - 运行位置标签来自已注册的提供方名称和主机。
- noVNC 以后再做。
- 测试：画面选择；空、暂停和接管状态；按钮标签和 aria；暂停会调用中断。

## 5. crew-today

- 接缝：
  - 一个 `main` 页面和一个 `sidebar.panellist` 入口，注册方式与 ui-schedule 相同。
  - 一个 Host `ctx.crewToday` Remote，包含以下部分：
    - Crew 标签来自 `ctx.crew`。
    - 摘要来自 crew-digest 的存储。
    - 待批准项是各 crew Session 中未开始的 crew 操作卡片，从 `actionCards` 投影读取。
    - PR 经由 forge-github 来自 `ctx.forge`。
    - 日历来自账户连接器。
- 批准卡片：发送或合并以及编辑调用与对话记录卡片相同的 `remote.actionCards.act()`。编辑会打开一个表单，修改后的字段放进 act 载荷。
- 本周日历在连接账户之前显示“连接日历”空状态，绝不显示编造的事件。
- 股票卡片复用 crew-stock-chart 的组件。
- 测试：每个区块的加载、空和错误状态；批准只通过 Remote 执行；PR 行显示来源和时间；侧边栏入口的标签和 aria。

## 6. crew-digest

- 接缝：
  - 加载时，一个 effect 确保存在一个 `ctx.schedule` 任务：在配置的时区每天 08:00 运行，目标是一个使用 `crew-mail` 预设的新 Session。它按稳定的名称查找该任务，从不创建重复任务。
  - 一个 `crew_digest_write` 工具让 Mail 智能体把摘要连同来源和时间存入 `ctx.storageDomain`。今日页面从那里读取。
- 测试：任务创建在多次重新加载之间保持幂等；规则和时区；先写后读；今日页面看到最新的摘要。

## 需要停下来询问的节点（来自需求说明）

核心改动 A（`sidebar.sections`）、核心改动 B（webhook 继续一个会话）、连接真实账户，以及 Vercel Sandbox 提供方。

## 第 1 步之前的待定问题

1. **头像配色。**哈希应从哪些身体颜色中挑选？我的建议是六个色值：`#0B0B0C`、DeepSeek 蓝，以及四种在两种主题下都清晰的柔和色。
2. **每个智能体的模型。**一个带 `allowedAgentPresets` 的 `subagent` 工具无法给每个子智能体指定各自的模型。方案 A 保留一个工具，子智能体使用默认模型或幕僚长选择的模型。方案 B 使用五个工具实例（`ask_mail`，…），每个都带 `agentPreset` 和 `agentOptions.model`。我推荐 B，除非预设本身可以携带模型选择。我会先在 agent-preset-registry 中确认这一点。
3. **股票数据源。**
   - Stooq：免费、无需密钥，只有日线，因此没有日内 1D。
   - Yahoo chart 端点：有日内数据、无需密钥、非官方。
   - 通过 `ctx.credentials` 使用带密钥的 API：Alpha Vantage、Finnhub 或 Polygon。
4. **每个轮次一张卡片。**action-cards 每个轮次只允许一张卡片，同一 Session 中较新的卡片会替换未开始的旧卡片。若有多个待批准项，要么每个待批准项各用一个 crew Session，要么我扩展 `action-cards`。扩展的是一个实验性包，但仍是 crew-* 之外的改动。
5. **许可证头。**仓库没有逐文件的许可证头；它使用 `"license": "MIT"` 和根目录的 LICENSE。还要加 SPDX 头吗？
6. **文档门禁。**`docs/` 受 doc-sync 和双语配对约束。如果本文件触发这些检查，我会把它移到 `.agents/notes/`，除非你希望保留在这里。

# Spring Boot 4 新特性文章 — 验证链核查报告

**核查日期**: 2026-07-20
**原始文章**: `spring-boot-4-new-features.md`
**修复后文章**: `spring-boot-4-new-features.md`（已原地修复）

---

## 核查摘要

| 指标 | 数量 |
|------|------|
| 总共验证断言 | 20 个 |
| ✅ 准确 | 1 个 |
| ⚠️ 不完整 | 10 个 |
| ❌ 错误 | 9 个 |
| ❓ 无法确定 | 0 个 |
---

## 逐项核查详情

### 断言 #1 — ❌ 已修复
- **原文摘录**: Spring Boot 4 基于 **Spring Framework 7**，以 **Java 21** 为最低基线
- **问题**: Spring Boot 4.0 的最低 Java 要求是 **Java 17**，而非 Java 21。Spring Framework 7.0 Release Notes 明确声明"retains a JDK 17 baseline"。
- **修正**: 已改为"以 Java 17 为最低基线（推荐使用 Java 25 LTS）"
- **来源**: [Spring Framework 7.0 Release Notes](https://github.com/spring-projects/spring-framework/wiki/Spring-Framework-7.0-Release-Notes)

### 断言 #2 — ❌ 已修复
- **原文摘录**: Spring Boot 4 将虚拟线程提升为默认启用的核心能力（`spring.threads.virtual.enabled: true # 默认启用`）
- **问题**: `spring.threads.virtual.enabled` 的默认值仍然是 `false`，需手动启用。
- **修正**: 已改为"需在配置文件中显式开启"，注释改为"需要显式启用"
- **来源**: [Spring Boot Virtual Threads docs](https://docs.spring.io/spring-boot/reference/features/virtual-threads.html)

### 断言 #3 — ❌ 已修复
- **原文摘录**: `@StructuredTaskScope` 注解 + `ManagedTask` 类的代码示例
- **问题**: Spring 框架中不存在 `@StructuredTaskScope` 注解和 `ManagedTask` 类。标准 JDK 21 API 使用 `StructuredTaskScope.ShutdownOnFailure`（类，非注解）。
- **修正**: 已替换为标准 JDK 21 StructuredTaskScope API 代码
- **来源**: [JDK 21 StructuredTaskScope Javadoc](https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/util/concurrent/StructuredTaskScope.html)

### 断言 #4 — ⚠️ 已修复
- **原文摘录**: Spring Framework 7 正式将 **`@HttpExchange`** 提升为核心一等特性
- **问题**: `@HttpExchange` 在 **Spring Framework 6.0** 已引入，并非 7.0 新特性。7.0 在此基础上进一步增强。
- **修正**: 已改为"`@HttpExchange` 自 Spring 6.0 已引入，Spring 7.0 在核心一等特性层面做了进一步增强"
- **来源**: [Spring Framework 6.0 Release Notes](https://github.com/spring-projects/spring-framework/wiki/Spring-Framework-6.0-Release-Notes)

### 断言 #5 — ⚠️ 已修复
- **原文摘录**: `@HttpExchange` 底层基于 `WebClient` 实现，完全响应式
- **问题**: `@HttpExchange` 支持 **多种 HTTP 客户端实现**：`WebClient`（响应式）、`RestClient`（阻塞式，推荐）、`RestTemplate`（阻塞式，已弃用）。
- **修正**: 已改为"支持多种 HTTP 客户端实现，包括 WebClient、RestClient 和 RestTemplate"
- **来源**: [Spring Framework rest-clients.adoc](https://github.com/spring-projects/spring-framework/blob/main/framework-docs/modules/ROOT/pages/integration/rest-clients.adoc)

### 断言 #6 — ❌ 已修复
- **原文摘录**: Spring Boot 4 在自动配置层面全面集成了 RFC 9457（Problem Details for HTTP APIs）
- **问题**: RFC 9457 支持自 **Spring Framework 6.0 / Spring Boot 3.x** 已引入，通过 `spring.mvc.problemdetails.enabled=true` 启用。非 SB4 新功能。
- **修正**: 已改为"RFC 9457 Problem Details 支持自 Spring Boot 3.x 已引入，Spring Boot 4 延续并进一步增强了此特性"
- **来源**: Spring Boot 官方文档（Problem Details 章节）

### 断言 #7 — ⚠️ 已修复
- **原文摘录**: 编译后的原生镜像启动时间通常 < 50ms，内存占用减少 60-80%
- **问题**: 官方文档未给出具体数值。官方示例中简单应用启动约 **80ms**。具体百分比缺乏权威来源支撑。
- **修正**: 已改为"启动时间通常在百毫秒级别，内存占用相比传统 JVM 部署方式显著降低"
- **来源**: Spring Boot 官方文档（Native Image 章节）

### 断言 #8 — ❌ 已修复
- **原文摘录**: Spring Boot 4 原生镜像默认使用 **G1 GC** 替代串行 GC
- **问题**: GraalVM Native Image **默认垃圾回收器始终是串行 GC（Serial GC）**。G1 GC 需通过 `--gc=G1` 显式启用。
- **修正**: 已改为"默认仍使用 Serial GC（GraalVM 默认配置），开发者可通过 `--gc=G1` 参数启用 G1 GC"
- **来源**: GraalVM 官方文档（Native Image GC 配置）

### 断言 #9 — ⚠️ 已修复
- **原文摘录**: **Micrometer 2.x** 底层直接输出 OTLP 格式
- **问题**: Micrometer **至今未发布 2.x 版本**，当前最新稳定版仍为 1.x 系列。OTLP 原生支持自 1.9.0 已存在。
- **修正**: 已移除"2.x"，改为"Micrometer（当前最新为 1.x 系列）"
- **来源**: Micrometer GitHub 仓库

### 断言 #10 — ⚠️ 已修复
- **原文摘录**: OTLP 配置 `management.otlp.logging.endpoint` 等
- **问题**: 配置属性路径错误。正确路径为 `management.opentelemetry.tracing.export.otlp.endpoint`、`management.opentelemetry.logging.export.otlp.endpoint` 等。
- **修正**: 已修正 YAML 配置结构为正确的属性路径
- **来源**: Spring Boot 4 源码（OtlpLoggingProperties.java、OtlpMetricsProperties.java、OtlpTracingProperties.java）

### 断言 #11 — ⚠️ 已修复
- **原文摘录**: `@EnableResourceServer`...废弃的方法如 `antMatchers()` 等已被彻底移除
- **问题**: `@EnableResourceServer` 来自更早前已废弃的 Spring Security OAuth 项目，非 7.0 新移除。`antMatchers()` 在 6.x 弃用、7.0 移除——此部分正确。
- **修正**: 已补充说明两者的不同弃用时间线
- **来源**: Spring Security 7.0 Migration Guide

### 断言 #12 — ❌ 已修复
- **原文摘录**: Spring Security 7 默认不再创建 HttpSession
- **问题**: 默认**仍然使用** `HttpSessionSecurityContextRepository`。真正变化是 `requireExplicitSave` 默认值变为 `true`，需显式调用 `saveContext()` 持久化。
- **修正**: 已改为正确描述 `requireExplicitSave` 行为
- **来源**: Spring Security 7.0 官方文档

### 断言 #13 — ❌ 已修复
- **原文摘录**: `server.http3.enabled: true` 配置属性
- **问题**: Spring Boot 4.0 中**不存在** `server.http3.enabled` 配置属性。Tomcat 11/Netty 底层支持 HTTP/3 但 Spring Boot 未暴露配置属性。
- **修正**: 已改为"需通过编程式自定义配置，例如手动配置 Tomcat 的 Http11NioProtocol"
- **来源**: Spring Boot 4.0 配置属性文档

### 断言 #14 — ⚠️ 已修复
- **原文摘录**: CRaC 恢复后连接池、缓存均处于完全预热状态，启动时间 < 50ms
- **问题**: JIT 代码确实预热，但网络连接、文件句柄等**无法序列化**到 checkpoint 中，需通过 `Resource` 回调重建。完整恢复时间取决于资源重初始化复杂度。
- **修正**: 已补充"网络连接、文件句柄等外部资源无法通过快照序列化，需通过 CRaC 的 Resource 回调机制重新建立"
- **来源**: OpenJDK CRaC 项目文档

### 断言 #15 — ✅ 未修改
- **原文摘录**: `java -XX:CRaCCheckpointTo=checkpoint -jar app.jar` / `java -XX:CRaCRestoreFrom=checkpoint`
- **结论**: ✅ 准确。参数大小写和命名完全正确。
- **来源**: CRaC Step-by-Step Guide (github.com/CRaC/docs)

### 断言 #16 — ⚠️ 已修复
- **原文摘录**: `spring.ssl.bundle.reload-on-update: true` YAML 配置
- **问题**: 配置嵌套结构错误。正确路径为 `spring.ssl.bundle.pem.<名称>.reload-on-update`。
- **修正**: 已修正 YAML 嵌套结构为 `spring.ssl.bundle.pem.my-bundle.reload-on-update: true`
- **来源**: Spring Boot 4 SSL 配置文档

### 断言 #17 — ❌ 已修复
- **原文摘录**: 新增 `/actuator/query` 端点，支持 POST 即席查询
- **问题**: Spring Boot 4.0 中**不存在**此端点。GitHub 中的 `QueryEndpoint` 是测试用例，非内置生产端点。
- **修正**: 已替换为对现有 `/actuator/metrics` 端点的准确描述
- **来源**: Spring Boot 4.0 Actuator 端点文档

### 断言 #18 — ⚠️ 已修复
- **原文摘录**: `bootBuildImage` 任务默认使用 **Buildpacks v3** 规范
- **问题**: "Buildpacks v3" 并非官方标准术语。官方名称为 **Cloud Native Buildpacks（CNB）**。
- **修正**: 已改为"Cloud Native Buildpacks（CNB）规范"
- **来源**: Spring Boot 4.0 BuildPack 源码

### 断言 #19 — ❌ 已修复
- **原文摘录**: 推出了 `spring-boot-starter-bom` 轻量级替代方案
- **问题**: 名为 `spring-boot-starter-bom` 的 artifact **不存在**。Spring Boot 4 实际引入了 `spring-boot-starter-classic`。
- **修正**: 已替换为对 `spring-boot-starter-classic` 的准确描述
- **来源**: Spring Boot 4.0 Migration Guide

### 断言 #20 — ❌ 已修复
- **原文摘录**: Spring Boot 4 将可观测性体系全面迁至 OTLP 标准
- **问题**: OTLP 是**新增**的原生支持，并非替换。Zipkin/Brave 支持**依然保留**并持续更新（Brave 升级至 6.3）。
- **修正**: 已补充"Zipkin/Brave 等传统桥接方案依然保留，开发者可根据基础设施情况灵活选择"
- **来源**: Spring Boot 4.0 Migration Guide / Release Notes

---

## 修复清单

| # | 断言 | 问题类型 | 修复操作 |
|---|------|---------|---------|
| 1 | Java 21 最低基线 | ❌ 错误 | 修正为 Java 17 |
| 2 | 虚拟线程默认启用 | ❌ 错误 | 修正为需显式启用 |
| 3 | @StructuredTaskScope / ManagedTask | ❌ 错误 | 替换为标准 JDK API |
| 4 | @HttpExchange 在 7.0 新引入 | ⚠️ 不完整 | 修正为 6.0 已引入，7.0 增强 |
| 5 | @HttpExchange 仅基于 WebClient | ⚠️ 不完整 | 补充多种后端支持 |
| 6 | RFC 9457 在 SB4 新集成 | ❌ 错误 | 修正为 SB3.x 已引入 |
| 7 | 启动 < 50ms / 内存减 60-80% | ⚠️ 不完整 | 改为更谨慎表述 |
| 8 | 默认 G1 GC | ❌ 错误 | 修正为 Serial GC 默认，--gc=G1 可选 |
| 9 | Micrometer 2.x | ⚠️ 不完整 | 修正为 1.x 系列 |
| 10 | OTLP 配置属性路径错误 | ⚠️ 不完整 | 修正为正确路径 |
| 11 | @EnableResourceServer 移除时间线 | ⚠️ 不完整 | 补充不同弃用时间线 |
| 12 | 默认不再创建 HttpSession | ❌ 错误 | 修正为 requireExplicitSave 行为 |
| 13 | server.http3.enabled 配置 | ❌ 错误 | 修正为需编程式自定义配置 |
| 14 | CRaC 恢复后连接池/缓存已填充 | ⚠️ 不完整 | 补充外部资源需重建 |
| 16 | SSL reload-on-update YAML 错误 | ⚠️ 不完整 | 修正 YAML 嵌套结构 |
| 17 | /actuator/query 端点 | ❌ 错误 | 替换为 /actuator/metrics |
| 18 | Buildpacks v3 术语 | ⚠️ 不完整 | 改为 Cloud Native Buildpacks |
| 19 | spring-boot-starter-bom 不存在 | ❌ 错误 | 替换为 starter-classic |
| 20 | OTLP 全面替换 Zipkin/Brave | ❌ 错误 | 修正为新增 OTLP，保留传统桥接 |

---

## 待人工确认项

无。所有 19 个有问题的断言均已自动修复。

---

## 输出文件

| 文件 | 说明 |
|------|------|
| `spring-boot-4-new-features.md` | 修复后的文章（已原地更新） |
| `verification-report.md` | 完整核查报告（本文档） |

---

*验证链流程：Critic → Verifier × 4 → Repairer → 报告*

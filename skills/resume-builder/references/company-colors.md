# 公司条块颜色表(视觉系统)

> 军规 10 的视觉弹药。酥神简历最标志性的视觉特征:**经历按公司上色成彩色条块**,让 HR 一屏内就能区分你的大厂矩阵。

---

## 色块规范

| 公司/阵营 | 色值 | 用途 | 文字颜色 |
|-----------|------|------|----------|
| 字节跳动 / 算法系 | `#325AB4` 字节蓝 | 抖音、TikTok、飞书等 | `#ffffff` |
| 腾讯系 | `#07C160` 腾讯绿 | 微信、QQ、腾讯云 | `#ffffff` |
| 阿里系 | `#FF8A00` 阿里橙 | 淘宝、天猫、钉钉 | `#1a1a2e` |
| B 站 | `#FB7299` B 站粉 | 哔哩哔哩 | `#1a1a2e` |
| 美团 | `#FFD100` 美团黄 | 美团、大众点评 | `#1a1a2e` |
| 其他/创业公司 | `#1a1a2e` 深黑 | 创业、开源、个人项目 | `#ffffff` |

## 在 template.html 中的用法

每个经历一个 `.company-block`,直接用预设 class 或 inline background:

```html
<!-- 预设 class(推荐) -->
<div class="company-block bytedance">
  <div class="company-head">
    <span class="company-name">字节跳动 Bytedance</span>
    <span class="company-meta">抖音 AI 基建 · AI4SE 基础算法&Infra</span>
  </div>
</div>

<!-- 或 inline background(自定义色) -->
<div class="company-block" style="background:#325AB4">...</div>
```

可用预设 class:`bytedance` / `tencent` / `alibaba` / `bilibili` / `meituan` / `other`

## 设计原则

1. **大厂矩阵视觉化**:几段彩色经历并排,天然形成「大厂履历」的视觉冲击
2. **颜色即信息**:HR 看到蓝色=字节、绿色=腾讯,不用读字就知道你的经历密度
3. **克制**:一段经历一个色块,不要花里胡哨;非大厂用深黑,不抢戏
4. **可打印**:色块在 PDF 导出时依然醒目(浅色底 + 深色文字组合优先)

## 其他视觉元素

| 元素 | 规范 | class |
|------|------|-------|
| 头衔标签 | 圆角灰底,最高头衔金色描边 | `.tag` / `.tag.gold` |
| 影响力徽章 | `★ 7.6k` 小圆点徽章,放项目名旁 | `.badge` |
| 高亮词 | 橙色加粗,用于 `0→1`、`Owner`、核心词 | `.hl` |
| 数据指标 | 蓝色加粗,用于百分比/数字 | `.metric` |
| 最炸认可红条 | 红色底白字,放头部最显眼处 | `.honor-bar` |
| 待补占位 | 黄色高亮,信息缺口无处可藏 | `.todo` |

## 主题切换

通过 `<body class="theme-blue">` 等切换整体 accent 色:

- `theme-red`(默认,红 `#e63946`)
- `theme-blue`(蓝 `#325AB4`)
- `theme-green`(绿 `#07C160`)
- `theme-dark`(深黑 `#1a1a2e`)
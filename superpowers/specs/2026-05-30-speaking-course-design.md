# 口语训练 + 英语课程 设计文档

## 目标

在 VocabApp 中新增两大功能模块：
1. **场景口语** — 英语 900 句风格的场景对话演练（混合模式：盲说→对照→跟读）
2. **英语课程** — 内置经典英语教材（新概念英语、走遍美国、Side by Side、VOA 慢速英语）

## Tab 结构调整

| 标签 | 内容 | 说明 |
|------|------|------|
| 单词 | LearningHomeView | 不变 |
| 口语 | OralTrainingView | 改造：场景列表 + 对话练习 |
| 课程 | CourseView | 新，替换原「阅读」tab |
| 看板 | DashboardView | 不变 |
| 我的 | SettingsView | 不变 |

## 口语 tab (OralTrainingView 改造)

### 页面结构

```
OralTrainingView
├── 首页：场景分类列表
│   ├── 顶部：搜索 + 分类筛选标签
│   └── 场景卡片列表（图标 + 标题 + 简短描述）
└── 对话练习页 (DialogPracticeView)
    ├── 进度条
    ├── 逐句对话角色扮演
    ├── 混合模式：盲说 → 对照 → 跟读
    └── 结果评分（星级 + 识别文本对照）
```

### 场景分类（17 类，~45 段对话）

| 分类 | 场景 |
|------|------|
| 日常起居 | 问候介绍、家人朋友、日常闲聊、时间日期 |
| 餐饮美食 | 餐厅点餐、咖啡馆、做饭 |
| 出行交通 | 问路、打车、公交地铁、租车 |
| 住宿旅行 | 酒店入住、客房服务、机场、问询 |
| 购物消费 | 试穿问价、讨价还价、退换货、超市 |
| 社交娱乐 | 电话、邀请聚会、兴趣爱好、影剧运动 |
| 职场商务 | 面试、会议、邮件、客户接待 |
| 紧急求助 | 看病就医、报警求助、失物招领 |

### 数据格式

```json
{
  "id": "greeting",
  "title": "问候与介绍",
  "icon": "hand.wave",
  "dialogues": [
    {
      "id": "greet_01",
      "title": "初次见面",
      "lines": [
        { "speaker": "A", "en": "...", "zh": "...", "audio": "" },
        { "speaker": "B", "en": "...", "zh": "..." }
      ]
    }
  ]
}
```

### 练习流程（混合模式）

1. 用户扮演角色（A 或 B）
2. **第一轮（盲说）**：对方的文字和语音正常显示播放，用户角色的英文隐藏，只显示中文提示 → 用户按住麦克风说出对应英文 → 释放后评分 + 显示原文对照
3. **第二轮（跟读）**：显示完整英文原文 → 用户跟读 → 评分
4. 每句重复 1-3，全部完成后展示该段对话总结

## 课程 tab (CourseView 新)

### 页面结构

```
CourseView（TabView 中 tag 2）
├── 教材列表页：分类展示 4 套教材
│   ├── 英式英语：新概念英语 1-4 册
│   ├── 美式英语：走遍美国、Side by Side 1-4 册
│   └── 新闻听力：VOA 慢速英语（30篇）
├── 课程序列页：选中教材后展示课程序列
└── 课文学习页 (LessonView)
    ├── 英文原文（点击句子发音）
    ├── 中文翻译（可切换显示）
    ├── 重点词汇表
    ├── 🎤 跟读本课
    └── 上/下一课导航
```

### 教材清单

| 教材 | 类型 | 规模 | 数据 |
|------|------|------|------|
| 新概念英语 1-4 | 英式 | ~288 课 | 内嵌 JSON |
| 走遍美国 | 美式 | 26 集 ×3 = 78 课 | 内嵌 JSON |
| Side by Side 1-4 | 美式 | ~200 课 | 内嵌 JSON |
| VOA 慢速英语 | 美式新闻 | 30 篇 | 内嵌 JSON |

### 数据格式

```json
{
  "id": "nce1",
  "title": "新概念英语 1",
  "author": "L.G. Alexander",
  "type": "british",
  "description": "英语初阶",
  "icon": "book.closed",
  "lessons": [
    {
      "id": "nce1_001",
      "title": "Lesson 1: Excuse me!",
      "text_en": "Excuse me!\nYes?",
      "text_zh": "对不起！\n什么事？",
      "vocabulary": [
        { "word": "excuse", "phonetic": "/ɪkˈskjuːz/", "meaning": "原谅" }
      ]
    }
  ]
}
```

### 课文学习页功能

- 英文原文显示，点击任一句子用 TTS 朗读
- 中文翻译默认隐藏，点击按钮切换显示
- 底部重点词汇卡片（点击发音）
- 「跟读本课」进入逐句跟读模式（复用口语的评分逻辑）
- 左右滑动或点击按钮切换上下课

## 技术方案

### 依赖
- SpeechRecognizerService（已有）
- AVSpeechSynthesizer（已有）
- SwiftUI（已有）

### 新增文件
- `Resources/Courses/scenarios.json` — 场景对话数据
- `Resources/Courses/nce.json` — 新概念英语数据
- `Resources/Courses/famu.json` — 走遍美国数据
- `Resources/Courses/sbs.json` — Side by Side 数据
- `Resources/Courses/voa.json` — VOA 慢速英语数据
- `Views/Courses/CourseListView.swift` — 课程/教材首页
- `Views/Courses/LessonView.swift` — 课文学习页面
- `Views/Courses/DialogPracticeView.swift` — 对话练习页面（场景口语）
- `Models/CourseModels.swift` — 教材/课程/对话数据模型

### 修改文件
- `Views/MainTabView.swift` — 替换阅读 tab 为课程 tab
- `Views/OralTrainingView.swift` — 改造为场景列表 + 对话入口
- `VocabApp.xcodeproj/project.pbxproj` — 添加新文件

### 数据生成
使用 Python 脚本生成全部 JSON 课程数据，嵌入 app bundle。

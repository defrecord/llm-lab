(princ "
src/
├── elisp/
│   └── llm-prerequisites.el
└── sql/
    ├── basic/
    │   ├── 01-total-conversations.sql
    │   ├── 02-conversations-by-date.sql
    │   └── 03-model-usage-stats.sql
    ├── advanced/
    │   ├── 01-response-time.sql
    │   ├── 02-token-trends.sql
    │   └── 03-text-search.sql
    ├── cost/
    │   └── 01-token-cost-analysis.sql
    └── usage/
        └── 01-usage-analysis.sql
")

(org-babel-tangle)

#!/bin/bash

# Register SIN Framework templates
llm templates save sin-framework << 'EOT'
### SIN Framework Selection Template ###
Analyze the input content and recommend the most appropriate analysis framework.

Available frameworks:
- SWOT: For strategic analysis (strengths, weaknesses, opportunities, threats)
- PEST/PESTLE: For macro-environmental analysis
- 5 Forces: For industry/competition analysis
- MoSCoW: For requirements prioritization
- RAID: For risk/assumption/issue/dependency analysis

Based on the content, output one line with selected framework and brief justification.
EOT

llm templates save sin-execution-plan << 'EOT'
### SIN Execution Plan Template ###
Given the selected framework, create a structured execution plan.

The plan will include:
1. Required data/inputs
2. Analysis steps
3. Expected outputs
4. Success criteria

Output the plan in clear, step-by-step format.
EOT

llm templates save sin-execute-and-document << 'EOT'
### SIN Analysis Execution Template ###
Following the execution plan:
1. Execute each analysis step
2. Document findings
3. Generate insights
4. Make recommendations

Output will be a comprehensive analysis document.
EOT

#!/usr/bin/env bash

declare -A guides=(
   [60]="llm"           
   [61]="kubectl"      
   [62]="uv"           
   [63]="git"          
   [64]="pre-commit"   
   [65]="hypothesis"   
   [66]="k6"          
   [67]="github-actions"
   [68]="opentelemetry"
   [69]="dvc"
   [70]="rfcs"         
   [71]="adrs"         
   [72]="distributed"  
   [73]="consensus"    
   [74]="profiling"    
)

mkdir -p .guides

# Create generic org template
llm template --system "Create org-mode documentation template with:
- Properties for tangling
- Setup sections for tool
- Configuration examples
- Practice exercises
- Common patterns
- Best practices
Output as complete org document." --save org-template --log -x

# Apply template to each guide
for num in "${!guides[@]}"; do
   name="${guides[$num]}"
   dirname=".guides/${num}-${name}"
   mkdir -p "$dirname"
   
   llm --template org-template -p tool="$name" --log > "${dirname}/README.org"
   echo "Generated guide for $name"
done

# Create index
llm "Generate org-mode index of all guides with descriptions" --log > ".guides/00-index.org"

tree .guides/

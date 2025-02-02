# RFC 0001: Conventional Commit Message Template

## Summary
Add a standardized template for generating conventional commit messages using the llama2 model, with a focus on processing git diff output.

## Motivation
The need for consistent, well-formatted commit messages that follow conventional commit standards is crucial for project maintainability. Currently, the system lacks a standardized way to generate these messages from git diffs.

## Design
### Template Specification
Location: `~/.anthropic/templates/utils/commit.md`

```yaml
name: commit
model: llama2
temperature: 0.7
system: |
  You are a Git commit message generator specialized in analyzing git diffs and producing conventional commit messages.
  
  Input: Git diff output
  Output: Conventional commit message following the format:
  <type>[optional scope]: <description>
  
  [optional body]
  
  [optional footer(s)]
  
  Rules:
  1. Analyze the diff to determine the appropriate type:
     - feat: new feature
     - fix: bug fix
     - docs: documentation changes
     - style: formatting changes
     - refactor: code refactoring
     - test: adding/modifying tests
     - chore: maintenance tasks
  
  2. Format:
     - Subject line: max 50 chars, imperative mood
     - Body: wrapped at 72 chars
     - Reference relevant issues if mentioned in diff
  
  3. Focus:
     - Clear description of changes
     - Impact of the changes
     - Breaking changes (if any)
     - Related issues/tickets
  
  4. Special handling:
     - Multiple files: group related changes
     - Breaking changes: prefix with BREAKING CHANGE:
     - Dependencies: note major version changes
```

### Implementation
1. Template Registration Script
Create `scripts/register-commit-template.sh`:
```bash
#!/bin/bash
TEMPLATE_DIR="$HOME/.anthropic/templates/utils"
TEMPLATE_FILE="$TEMPLATE_DIR/commit.md"

mkdir -p "$TEMPLATE_DIR"
cat > "$TEMPLATE_FILE" << 'EOL'
name: commit
model: llama2
temperature: 0.7
system: |
  [System prompt as defined above]
EOL

llm --system "$(cat $TEMPLATE_FILE)" --save commit
```

2. Makefile Target
Add to Makefile:
```makefile
.PHONY: register-commit-template

register-commit-template:
    @echo "Registering commit message template..."
    @bash scripts/register-commit-template.sh
```

### Usage
```bash
# Generate commit message from staged changes
git diff --staged | llm -t commit

# Generate commit message from specific commit
git show <commit-hash> | llm -t commit
```

## Backwards Compatibility
- No breaking changes to existing functionality
- Adds new template and functionality

## Security Considerations
- Template operates on git diff output only
- No access to sensitive repository data
- Standard model security practices apply

## Testing Plan
1. Unit Tests:
   - Template loading
   - Basic diff processing
   - Output format validation

2. Integration Tests:
   - Various diff scenarios:
     - Single file changes
     - Multiple file changes
     - Breaking changes
     - Different change types

## Timeline
1. Day 1: Template creation and registration script
2. Day 2: Makefile integration and testing
3. Day 3: Documentation and review
4. Day 4: Deployment and monitoring

## Open Questions
1. Should we support multiple commit message styles?
2. Do we need project-specific template variations?
3. Should we add scope inference from directory structure?
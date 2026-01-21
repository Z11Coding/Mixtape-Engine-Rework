# Function Highlighting Added! 🎨

## New Function Scopes Added:

### Function Definitions:
- Scope: `entity.name.function.definition.yscript`
- Usage: `function myFunction() { ... }`
- Color: Should appear distinct from other text

### Function Calls:
- Scope: `entity.name.function.call.yscript`
- Usage: `myFunction()`
- Color: Different from function definitions

### Method Calls:
- Scope: `entity.name.function.method.yscript`
- Usage: `object.methodName()`
- Color: Distinct from regular function calls

## How to Test:

1. **Reload the Extension**: In VS Code Extension Development Host, reload the window (Ctrl+R) or restart
2. **Open example.ys**: Now contains function highlighting test cases
3. **Verify Colors**:
   - Function definitions should have one color
   - Function calls should have a different color
   - Method calls should have their own distinct color

## Color Customization:

Add to your VS Code settings.json to customize colors:

```json
{
  "editor.tokenColorCustomizations": {
    "textMateRules": [
      {
        "scope": "entity.name.function.definition.yscript",
        "settings": {
          "foreground": "#4FC3F7",
          "fontStyle": "bold"
        }
      },
      {
        "scope": "entity.name.function.call.yscript",
        "settings": {
          "foreground": "#81C784"
        }
      },
      {
        "scope": "entity.name.function.method.yscript",
        "settings": {
          "foreground": "#FFB74D"
        }
      }
    ]
  }
}
```

The function highlighting is now active! 🚀

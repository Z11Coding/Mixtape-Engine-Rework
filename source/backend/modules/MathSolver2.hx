package backend.modules;

class MathSolver2 {
    var variables:Map<String, Dynamic>;

    public function new() {
        variables = new Map<String, Dynamic>();
    }

    public function evaluate(expression: String): Dynamic {
        // Handle equation solving
        if (expression.indexOf('=') > -1) {
            return solveEquation(expression);
        }

        // Replace variables with their values
        for (variable in variables.keys()) {
            expression = expression.replace(variable, Std.string(variables.get(variable)));
        }

        // Handle custom operator '&'
        expression = replaceCustomOperators(expression);

        // Parse and evaluate the expression
        return eval(parse(expression));
    }

    public function setVariable(name: String, value: Dynamic): Void {
        variables.set(name, value);
    }

    private function replaceCustomOperators(expression: String): String {
        var customPattern = ~/(\d+)\s*&\s*(\d+)/;
        while (customPattern.match(expression)) {
            var matched = customPattern.matched(0);
            var parts = matched.split("&").map(s -> Std.parseInt(s.trim()));
            var result = Std.string(parts[0]) + Std.string(parts[1]);
            expression = expression.replace(matched, result);
        }
        return expression;
    }

    private function parse(expression: String): Dynamic {
        // This is a simplified parser. You can use a more robust parser for complex expressions.
        return Parser.parseString(expression);
    }

    private function eval(node: Dynamic): Dynamic {
        switch(node.expr) {
            case EConst(c):
                return Std.parseFloat(c);
            case EBinop(op, left, right):
                var l = eval(left);
                var r = eval(right);
                switch(op) {
                    case Add: return l + r;
                    case Sub: return l - r;
                    case Mul: return l * r;
                    case Div: return l / r;
                    case Pow: return Math.pow(l, r);
                    default: throw "Unsupported operator";
                }
            default:
                throw "Unsupported expression";
        }
    }

    private function solveEquation(expression: String): Dynamic {
        var parts = expression.split('=');
        if (parts.length != 2) throw "Invalid equation";

        var left = parts[0].trim();
        var right = parts[1].trim();

        // Evaluate the right-hand side
        var rhsValue = evaluate(right);

        // Find the variable in the left-hand side
        var variablePattern = ~/([a-zA-Z]+)/;
        if (!variablePattern.match(left)) throw "No variable found to solve for";
        
        var variable = variablePattern.matched(1);
        var equationWithoutVariable = left.replace(variable, "0");

        // Evaluate the left-hand side without the variable
        var lhsWithoutVariableValue = evaluate(equationWithoutVariable);

        // Solve for the variable
        var variableValue = rhsValue - lhsWithoutVariableValue;

        return variable + " = " + variableValue;
    }
}

class Parser {
    public static function parseString(expression: String): Dynamic {
        // Simplified parser for demonstration. Implement a full parser for complex expressions.
        var tokens = expression.split(" ");
        var stack = [];
        for (token in tokens) {
            switch(token) {
                case "+":
                    stack.push({ expr: EBinop(Add, stack.pop(), parseToken(tokens.shift())) });
                case "-":
                    stack.push({ expr: EBinop(Sub, stack.pop(), parseToken(tokens.shift())) });
                case "*":
                    stack.push({ expr: EBinop(Mul, stack.pop(), parseToken(tokens.shift())) });
                case "/":
                    stack.push({ expr: EBinop(Div, stack.pop(), parseToken(tokens.shift())) });
                case "^":
                    stack.push({ expr: EBinop(Pow, stack.pop(), parseToken(tokens.shift())) });
                default:
                    stack.push(parseToken(token));
            }
        }
        return stack.length > 1 ? { expr: EBinop(Add, stack[0], stack[1]) } : stack[0];
    }

    private static function parseToken(token: String): Dynamic {
        return { expr: EConst(token) };
    }
}

// Define expression types
enum Expr {
    EConst(exp: String);
    EBinop(e: Binop, o: Dynamic, d: Dynamic);
    ECustom(exp: String, o: Dynamic, d: Dynamic);
}

enum Binop {
    Add;
    Sub;
    Mul;
    Div;
    Pow;
}

// Example usage
// class Main {
//     static public function main():Void {
//         var solver = new MathSolver();

//         // Directly solving an equation
//         var expression = "a + 39 = 48";
//         trace("Original Expression: " + expression);
//         trace("Solution: " + solver.evaluate(expression));

//         // Using variables and evaluating complex expression
//         solver.setVariable("a", 3);
//         solver.setVariable("b", 8);
//         solver.setVariable("c", 2);

//         var complexExpression = "23a + (32 & 2) - 5 * 3 + (b / c)";
//         trace("Original Expression: " + complexExpression);
//         trace("Evaluated Result: " + solver.evaluate(complexExpression));
//     }
// }

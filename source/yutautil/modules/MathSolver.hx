package backend.modules;

import haxe.ds.StringMap;

class MathSolver {
	var variables: StringMap<Float>;

	public function new() {
		variables = new StringMap<Float>();
	}

	public function setVariable(name: String, value: Float): Void {
		variables.set(name, value);
	}

    public function evaluate(expression: String): Dynamic {
        // This is a simplified example. A full implementation would require parsing and evaluating the expression.
        // For demonstration, let's handle a simple case with the '&' operator.
        var result = 0;
        var parts = expression.split('&');
        for (i in 0...parts.length) {
            var part = parts[i];
            // Simple evaluation of addition for demonstration
            if (part.indexOf('+') > -1) {
                var nums = part.split('+').map(s -> Std.parseFloat(s));
                result += nums.reduce((a, b) -> a + b);
            } else if (part.indexOf('-') > -1) {
                var nums = part.split('-').map(s -> Std.parseFloat(s));
                result -= nums.reduce((a, b) -> a + b);
            } else if (part.indexOf('*') > -1) {
                var nums = part.split('*').map(s -> Std.parseFloat(s));
                result *= nums.reduce((a, b) -> a * b);
            } else if (part.indexOf('/') > -1) {
                var nums = part.split('/').map(s -> Std.parseFloat(s));
                result /= nums.reduce((a, b) -> a / b);
            } else {
                result = Std.parseFloat(part); // Simplified, assumes single number or variable
            }
        }
        return result;
    }
}


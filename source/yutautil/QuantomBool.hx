class QuantumBool {
	private var probability: Float;

	public function new(probability: Float) {
		if (probability < 0 || probability > 1) {
			throw "Probability must be between 0 and 1";
		}
		this.probability = probability;
	}

	public function getProbability(): Float {
		return this.probability;
	}

	public function setProbability(probability: Float): Void {
		if (probability < 0 || probability > 1) {
			throw "Probability must be between 0 and 1";
		}
		this.probability = probability;
	}

	public function collapse(): Bool {
		return Math.random() < this.probability;
	}
}

enum QuantumBoolState {
	true,
	false,
	deci
}

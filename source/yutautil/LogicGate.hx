class LogicGate {
    private var result: Bool;

    public function new(initialValue: Bool) {
        this.result = initialValue;
    }

    public function and(value: Bool): LogicGate {
        this.result = this.result && value;
        return this;
    }

    public function or(value: Bool): LogicGate {
        this.result = this.result || value;
        return this;
    }

    public function not(): LogicGate {
        this.result = !this.result;
        return this;
    }

    public function xor(value: Bool): LogicGate {
        this.result = this.result != value;
        return this;
    }

    public function getResult(): Bool {
        return this.result;
    }
}
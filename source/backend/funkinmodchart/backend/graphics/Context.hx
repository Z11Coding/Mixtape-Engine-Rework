package backend.funkinmodchart.backend.graphics;

import backend.funkinmodchart.backend.graphics.renderers.*;
import backend.funkinmodchart.backend.math.View3D;
import backend.funkinmodchart.engine.PlayField;

class Context {
	public var parent:PlayField;
	public var view:View3D;

	public var arrowRenderer:ArrowRenderer;
	public var holdRenderer:HoldRenderer;
	public var pathRenderer:PathRenderer;

	public function new(parent:PlayField) {
		this.parent = parent;

		arrowRenderer = new ArrowRenderer(parent);
		holdRenderer = new HoldRenderer(parent);
		pathRenderer = new PathRenderer(parent);

		view = new View3D();
	}
}

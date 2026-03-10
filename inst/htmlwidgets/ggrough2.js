HTMLWidgets.widget({

  name: "ggrough2",

  type: "output",

  factory: function(el, width, height) {

    function copyAttributes(from, to) {
      for (let i = 0; i < from.attributes.length; i++) {
        const attr = from.attributes[i];
        if (!to.hasAttribute(attr.name)) {
          to.setAttribute(attr.name, attr.value);
        }
      }
    }

    function numericAttr(node, name, fallback = 0) {
      const v = node.getAttribute(name);
      return v == null ? fallback : parseFloat(v);
    }

    function styleStroke(node) {
      return node.getAttribute("stroke") || "black";
    }

    function styleFill(node) {
      const fill = node.getAttribute("fill");
      return (fill == null || fill === "none") ? "none" : fill;
    }

    function styleStrokeWidth(node) {
      const sw = node.getAttribute("stroke-width");
      return sw == null ? 1 : parseFloat(sw);
    }

    function roughOpts(node, userOpts) {
      const out = {
        roughness: userOpts.roughness,
        bowing: userOpts.bowing,
        fillStyle: userOpts.fillStyle,
        stroke: styleStroke(node),
        strokeWidth: styleStrokeWidth(node),
        seed: userOpts.seed
      };

      const fill = styleFill(node);
      if (fill !== "none") out.fill = fill;

      return out;
    }

    function replaceNode(oldNode, newNode) {
      if (newNode) {
        copyAttributes(oldNode, newNode);
        oldNode.parentNode.replaceChild(newNode, oldNode);
      }
    }

    function roughenSvg(svg, opts) {
      const rc = rough.svg(svg);

      const nodes = Array.from(svg.querySelectorAll("*"));

      nodes.forEach(node => {
        const tag = node.tagName.toLowerCase();

        if (opts.preserveText && tag === "text") return;

        try {
          if (tag === "line") {
            const x1 = numericAttr(node, "x1");
            const y1 = numericAttr(node, "y1");
            const x2 = numericAttr(node, "x2");
            const y2 = numericAttr(node, "y2");
            const newNode = rc.line(x1, y1, x2, y2, roughOpts(node, opts));
            replaceNode(node, newNode);
          } else if (tag === "rect") {
            const x = numericAttr(node, "x");
            const y = numericAttr(node, "y");
            const w = numericAttr(node, "width");
            const h = numericAttr(node, "height");
            const newNode = rc.rectangle(x, y, w, h, roughOpts(node, opts));
            replaceNode(node, newNode);
          } else if (tag === "circle") {
            const cx = numericAttr(node, "cx");
            const cy = numericAttr(node, "cy");
            const r = numericAttr(node, "r");
            const newNode = rc.circle(cx, cy, 2 * r, roughOpts(node, opts));
            replaceNode(node, newNode);
          } else if (tag === "ellipse") {
            const cx = numericAttr(node, "cx");
            const cy = numericAttr(node, "cy");
            const rx = numericAttr(node, "rx");
            const ry = numericAttr(node, "ry");
            const newNode = rc.ellipse(cx, cy, 2 * rx, 2 * ry, roughOpts(node, opts));
            replaceNode(node, newNode);
          } else if (tag === "polygon") {
            const pts = (node.getAttribute("points") || "")
              .trim()
              .split(/\s+/)
              .map(pair => pair.split(",").map(Number));
            const newNode = rc.polygon(pts, roughOpts(node, opts));
            replaceNode(node, newNode);
          } else if (tag === "polyline") {
            const pts = (node.getAttribute("points") || "")
              .trim()
              .split(/\s+/)
              .map(pair => pair.split(",").map(Number));
            const newNode = rc.linearPath(pts, roughOpts(node, opts));
            replaceNode(node, newNode);
          } else if (tag === "path") {
            const d = node.getAttribute("d");
            if (d) {
              const newNode = rc.path(d, roughOpts(node, opts));
              replaceNode(node, newNode);
            }
          }
        } catch (e) {
          // Leave unsupported or problematic nodes unchanged
        }
      });
    }

    return {
      renderValue: function(x) {
        el.innerHTML = "";

        const wrapper = document.createElement("div");
        wrapper.innerHTML = x.svg;
        const svg = wrapper.querySelector("svg");

        if (!svg) {
          el.textContent = "No SVG found.";
          return;
        }

        svg.style.maxWidth = "100%";
        svg.style.height = "auto";
        el.appendChild(svg);

        if (typeof rough === "undefined") {
          console.error("roughjs is not available");
          return;
        }

        roughenSvg(svg, x.options || {});
      },

      resize: function(width, height) {
        // no-op
      }
    };
  }
});
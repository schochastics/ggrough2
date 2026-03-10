HTMLWidgets.widget({
  name: "ggrough2",
  type: "output",

  factory: function(el, width, height) {
    return {
      renderValue: function(x) {
        el.innerHTML = "";

        var opts = x.options || {};

        if (typeof svg2roughjs === "undefined" || typeof svg2roughjs.Svg2Roughjs === "undefined") {
          el.textContent = "Error: svg2roughjs library not loaded.";
          return;
        }

        // Parse SVG string into DOM element
        var parser = new DOMParser();
        var doc = parser.parseFromString(x.svg, "image/svg+xml");
        if (doc.querySelector("parsererror")) {
          el.textContent = "Error: Failed to parse SVG.";
          return;
        }
        var sourceSvg = doc.documentElement;

        // Apply custom font to source SVG text elements so svg2roughjs
        // picks it up via getComputedStyle when building the output SVG.
        if (x.font) {
          sourceSvg.querySelectorAll("text, tspan").forEach(function(el) {
            el.style.fontFamily = '"' + x.font.name + '"';
          });
        }

        // svg2roughjs checks document.body.contains() and reads <style> elements,
        // so the source SVG must be attached to the live DOM (hidden).
        var hiddenHolder = document.createElement("div");
        Object.assign(hiddenHolder.style, {
          position: "absolute", visibility: "hidden",
          pointerEvents: "none", top: "-9999px", left: "-9999px"
        });
        hiddenHolder.appendChild(sourceSvg);
        document.body.appendChild(hiddenHolder);

        var targetContainer = document.createElement("div");
        targetContainer.style.width = "100%";
        el.appendChild(targetContainer);

        var roughConfig = {
          roughness: opts.roughness !== undefined ? opts.roughness : 1.5,
          bowing:    opts.bowing    !== undefined ? opts.bowing    : 1,
          fillStyle: opts.fillStyle || "hachure"
        };

        var converter = new svg2roughjs.Svg2Roughjs(
          targetContainer, svg2roughjs.OutputType.SVG, roughConfig
        );

        if (opts.seed !== null && opts.seed !== undefined) {
          converter.seed = opts.seed;
        }

        // preserveText: null skips svg2roughjs's font-size shrinking loop (triggered
        // when fontFamily !== null) while still inheriting source SVG fonts (falsy
        // check inside svg2roughjs). Empty string would also inherit fonts but
        // !== null triggers aggressive font shrinking on clipped text elements.
        if (opts.preserveText) {
          converter.fontFamily = null;
        }

        converter.svg = sourceSvg;

        (async function() {
          try {
            var roughSvg = await converter.sketch();
            if (roughSvg instanceof SVGElement) {
              // Inject @font-face into the output SVG so the browser can render it.
              if (x.font) {
                var style = document.createElementNS("http://www.w3.org/2000/svg", "style");
                style.textContent = '@font-face { font-family: "' + x.font.name +
                  '"; src: url("' + x.font.data_uri + '"); }';
                roughSvg.insertBefore(style, roughSvg.firstChild);
              }
              roughSvg.style.maxWidth = "100%";
              roughSvg.style.height = "auto";
              roughSvg.style.display = "block";
            }
          } catch(err) {
            el.innerHTML = "";
            el.textContent = "Error rendering sketch: " + err.message;
            console.error("svg2roughjs sketch() failed:", err);
          } finally {
            if (hiddenHolder.parentNode) document.body.removeChild(hiddenHolder);
          }
        })();
      },

      resize: function(width, height) {
        // Responsive sizing handled via CSS (maxWidth/height:auto). No re-render needed.
      }
    };
  }
});

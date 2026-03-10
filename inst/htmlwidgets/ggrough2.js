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
          sourceSvg.querySelectorAll("text, tspan").forEach(function(node) {
            node.style.fontFamily = '"' + x.font.name + '"';
          });
        }

        // svg2roughjs checks document.body.contains() and reads <style> elements,
        // so the source SVG must be attached to the live DOM (hidden).
        var hiddenHolder = document.createElement("div");
        Object.assign(hiddenHolder.style, {
          position: "absolute", visibility: "hidden",
          pointerEvents: "none", top: "-9999px", left: "-9999px"
        });
        document.body.appendChild(hiddenHolder);

        var roughConfig = {
          roughness: opts.roughness !== undefined ? opts.roughness : 1.5,
          bowing:    opts.bowing    !== undefined ? opts.bowing    : 1,
          fillStyle: opts.fillStyle || "hachure"
        };

        var bgFillStyle = opts.bgFillStyle !== undefined ? opts.bgFillStyle : opts.fillStyle || "hachure";
        var twoPass = bgFillStyle !== roughConfig.fillStyle;

        (async function() {
          try {
            if (!twoPass) {
              // ── Single-pass path (styles identical) ──────────────────────
              hiddenHolder.appendChild(sourceSvg);

              var targetContainer = document.createElement("div");
              targetContainer.style.width = "100%";
              el.appendChild(targetContainer);

              var converter = new svg2roughjs.Svg2Roughjs(
                targetContainer, svg2roughjs.OutputType.SVG, roughConfig
              );
              if (opts.seed !== null && opts.seed !== undefined) converter.seed = opts.seed;
              if (opts.preserveText) converter.fontFamily = null;
              converter.svg = sourceSvg;

              var roughSvg = await converter.sketch();
              if (roughSvg instanceof SVGElement) {
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

            } else {
              // ── Two-pass path (bg and fg use different fill styles) ───────
              // Identify background rects: ggplot2 always clips geom elements to the
              // panel viewport, so data rects (bars, tiles, etc.) live inside a
              // <g clip-path="..."> group. Panel/plot background rects never do.
              function isBackgroundRect(rect) {
                var parent = rect.parentNode;
                if (!parent) return false;
                if (parent.getAttribute && parent.getAttribute("clip-path")) return false;
                return true;
              }

              var allRects = Array.from(sourceSvg.querySelectorAll("rect"));
              var bgRects  = allRects.filter(isBackgroundRect);
              var fgRects  = allRects.filter(function(r) { return !isBackgroundRect(r); });

              // BG clone: keep only background rects; hide geom elements and fg rects
              var bgSvg = sourceSvg.cloneNode(true);
              bgSvg.querySelectorAll("path, line, circle, ellipse, polygon, polyline").forEach(function(n) {
                n.style.display = "none";
              });
              // Hide fg rects in bg clone by matching index in allRects
              var bgCloneRects = Array.from(bgSvg.querySelectorAll("rect"));
              fgRects.forEach(function(r) {
                var idx = allRects.indexOf(r);
                if (idx !== -1 && bgCloneRects[idx]) bgCloneRects[idx].style.display = "none";
              });

              // FG clone: make background rects invisible so svg2roughjs skips their fill
              var fgSvg = sourceSvg.cloneNode(true);
              var fgCloneRects = Array.from(fgSvg.querySelectorAll("rect"));
              bgRects.forEach(function(r) {
                var idx = allRects.indexOf(r);
                if (idx !== -1 && fgCloneRects[idx]) {
                  fgCloneRects[idx].setAttribute("fill", "none");
                  fgCloneRects[idx].setAttribute("stroke", "none");
                }
              });

              hiddenHolder.appendChild(bgSvg);
              hiddenHolder.appendChild(fgSvg);

              // BG pass
              var bgContainer = document.createElement("div");
              bgContainer.style.width = "100%";
              var bgConverterConfig = Object.assign({}, roughConfig, { fillStyle: bgFillStyle });
              var bgConverter = new svg2roughjs.Svg2Roughjs(
                bgContainer, svg2roughjs.OutputType.SVG, bgConverterConfig
              );
              if (opts.seed !== null && opts.seed !== undefined) bgConverter.seed = opts.seed;
              if (opts.preserveText) bgConverter.fontFamily = null;
              bgConverter.svg = bgSvg;
              var bgRoughSvg = await bgConverter.sketch();

              // FG pass
              var fgContainer = document.createElement("div");
              fgContainer.style.width = "100%";
              var fgConverter = new svg2roughjs.Svg2Roughjs(
                fgContainer, svg2roughjs.OutputType.SVG, roughConfig
              );
              if (opts.seed !== null && opts.seed !== undefined) fgConverter.seed = opts.seed;
              if (opts.preserveText) fgConverter.fontFamily = null;
              fgConverter.svg = fgSvg;
              var fgRoughSvg = await fgConverter.sketch();

              // Inject font into fg SVG (sits on top; applies to text elements)
              if (x.font && fgRoughSvg instanceof SVGElement) {
                var fgStyle = document.createElementNS("http://www.w3.org/2000/svg", "style");
                fgStyle.textContent = '@font-face { font-family: "' + x.font.name +
                  '"; src: url("' + x.font.data_uri + '"); }';
                fgRoughSvg.insertBefore(fgStyle, fgRoughSvg.firstChild);
              }

              // Layer: bg provides intrinsic height; fg is absolutely overlaid
              var wrapper = document.createElement("div");
              Object.assign(wrapper.style, { position: "relative", width: "100%" });
              el.appendChild(wrapper);

              if (bgRoughSvg instanceof SVGElement) {
                Object.assign(bgRoughSvg.style, {
                  width: "100%", height: "auto", display: "block"
                });
                wrapper.appendChild(bgRoughSvg);
              }

              if (fgRoughSvg instanceof SVGElement) {
                var fgWrap = document.createElement("div");
                Object.assign(fgWrap.style, {
                  position: "absolute", top: "0", left: "0",
                  width: "100%", height: "100%"
                });
                Object.assign(fgRoughSvg.style, {
                  width: "100%", height: "100%", display: "block"
                });
                fgWrap.appendChild(fgRoughSvg);
                wrapper.appendChild(fgWrap);
              }
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

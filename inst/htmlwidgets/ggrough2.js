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

        var parser = new DOMParser();
        var doc = parser.parseFromString(x.svg, "image/svg+xml");
        if (doc.querySelector("parsererror")) {
          el.textContent = "Error: Failed to parse SVG.";
          return;
        }
        var sourceSvg = doc.documentElement;

        if (x.font) {
          sourceSvg.querySelectorAll("text, tspan").forEach(function(node) {
            node.style.fontFamily = '"' + x.font.name + '"';
          });
        }

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
              var geomTags = new Set(["path", "line", "circle", "ellipse", "polygon", "polyline"]);
              function isBackgroundRect(rect) {
                var siblings = rect.parentNode ? rect.parentNode.children : [];
                for (var i = 0; i < siblings.length; i++) {
                  if (siblings[i] === rect) return true;
                  if (geomTags.has(siblings[i].tagName.toLowerCase())) return false;
                }
                return false;
              }

              var allRects = Array.from(sourceSvg.querySelectorAll("rect"));
              var bgRects  = allRects.filter(isBackgroundRect);
              var fgRects  = allRects.filter(function(r) { return !isBackgroundRect(r); });

              var bgSvg = sourceSvg.cloneNode(true);
              bgSvg.querySelectorAll("path, line, circle, ellipse, polygon, polyline").forEach(function(n) {
                n.style.display = "none";
              });

              var bgCloneRects = Array.from(bgSvg.querySelectorAll("rect"));
              fgRects.forEach(function(r) {
                var idx = allRects.indexOf(r);
                if (idx !== -1 && bgCloneRects[idx]) bgCloneRects[idx].style.display = "none";
              });

              var fgSvg = sourceSvg.cloneNode(true);
              var fgCloneRects = Array.from(fgSvg.querySelectorAll("rect"));
              bgRects.forEach(function(r) {
                var idx = allRects.indexOf(r);
                if (idx !== -1 && fgCloneRects[idx]) {
                  fgCloneRects[idx].style.fill = "none";
                  fgCloneRects[idx].style.stroke = "none";
                }
              });

              hiddenHolder.appendChild(bgSvg);
              hiddenHolder.appendChild(fgSvg);

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

              var fgContainer = document.createElement("div");
              fgContainer.style.width = "100%";
              var fgConverter = new svg2roughjs.Svg2Roughjs(
                fgContainer, svg2roughjs.OutputType.SVG, roughConfig
              );
              if (opts.seed !== null && opts.seed !== undefined) fgConverter.seed = opts.seed;
              if (opts.preserveText) fgConverter.fontFamily = null;
              fgConverter.svg = fgSvg;
              var fgRoughSvg = await fgConverter.sketch();

              if (x.font && fgRoughSvg instanceof SVGElement) {
                var fgStyle = document.createElementNS("http://www.w3.org/2000/svg", "style");
                fgStyle.textContent = '@font-face { font-family: "' + x.font.name +
                  '"; src: url("' + x.font.data_uri + '"); }';
                fgRoughSvg.insertBefore(fgStyle, fgRoughSvg.firstChild);
              }

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

      }
    };
  }
});

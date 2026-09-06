// WebGL renderer spoof — runs at document_start in the MAIN world.
//
// Root cause it defends against: a GPU-less Chromium (headless, or headed inside
// a container without /dev/dri) falls back to SwiftShader software rendering, so
// UNMASKED_RENDERER_WEBGL reports "ANGLE (... SwiftShader driver)". Bot
// detection fingerprints exactly this string, while a real user reports a
// hardware GPU. We rewrite the two unmasked
// parameters to a plausible Linux/Mesa Intel GPU, consistent with
// navigator.platform = "Linux x86_64" (a Windows/D3D11 string here would itself
// be an inconsistency tell).
(() => {
  // WebGL_debug_renderer_info enum values (stable, spec-defined).
  const UNMASKED_VENDOR_WEBGL = 0x9245;
  const UNMASKED_RENDERER_WEBGL = 0x9246;

  const SPOOF = {
    [UNMASKED_VENDOR_WEBGL]: "Google Inc. (Intel)",
    [UNMASKED_RENDERER_WEBGL]:
      "ANGLE (Intel, Mesa Intel(R) UHD Graphics 630 (CFL GT2), OpenGL 4.6 (Core Profile) Mesa 23.2.1)"
  };

  const patch = (proto) => {
    if (!proto || !proto.getParameter || proto.getParameter.__spoofed) return;
    const orig = proto.getParameter;
    const wrapped = function (parameter) {
      if (parameter === UNMASKED_VENDOR_WEBGL || parameter === UNMASKED_RENDERER_WEBGL) {
        return SPOOF[parameter];
      }
      return orig.call(this, parameter);
    };
    // Make the override look native to toString-based detectors.
    try {
      Object.defineProperty(wrapped, "name", { value: "getParameter" });
      Object.defineProperty(wrapped, "length", { value: 1 });
      wrapped.toString = () => "function getParameter() { [native code] }";
    } catch (e) {}
    wrapped.__spoofed = true;
    proto.getParameter = wrapped;
  };

  patch(self.WebGLRenderingContext && self.WebGLRenderingContext.prototype);
  patch(self.WebGL2RenderingContext && self.WebGL2RenderingContext.prototype);
})();

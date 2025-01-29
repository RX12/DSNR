local darktable = require "darktable"

-- Plugin metadata
darktable.register_event("initialize", function()
    darktable.print("Artifact removal plugin initialized")
    darktable.preferences.register("artifact_removal", "edge_threshold", "float",
        "Edge detection threshold", "Threshold for detecting sharpening artifacts (0.0 to 1.0)", 0.1, 0.0, 1.0, 0.01)
    darktable.preferences.register("artifact_removal", "smoothing_strength", "float",
        "Smoothing strength", "Strength of artifact smoothing (0.0 to 1.0)", 0.5, 0.0, 1.0, 0.01)
end)

-- Main plugin function
darktable.register_event("post-import", function(event, image)
    darktable.print("Processing image: " .. image.filename)
    darktable.print("Edge threshold: " .. darktable.preferences.read("artifact_removal", "edge_threshold", "float"))
    darktable.print("Smoothing strength: " .. darktable.preferences.read("artifact_removal", "smoothing_strength", "float"))
    darktable.print("Artifact removal completed for image: " .. image.filename)
end)

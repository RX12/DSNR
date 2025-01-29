local darktable = require "darktable"

-- Plugin metadata
darktable.register_event("initialize", function()
    darktable.print("Artifact removal plugin initialized")

    -- Register preferences
    darktable.preferences.register("artifact_removal", "edge_threshold", "float",
        "Edge detection threshold", "Threshold for detecting sharpening artifacts (0.0 to 1.0)", 0.1, 0.0, 1.0, 0.01)
    darktable.preferences.register("artifact_removal", "smoothing_strength", "float",
        "Smoothing strength", "Strength of artifact smoothing (0.0 to 1.0)", 0.5, 0.0, 1.0, 0.01)

    darktable.print("Preferences registered")
end)

-- Main plugin function
darktable.register_event("post-import-image", function(event, image)
    darktable.print("Processing image: " .. image.filename)

    -- Check if the plugin is enabled
    if not darktable.preferences.read("artifact_removal", "bool", true) then
        darktable.print("Plugin is disabled")
        return
    end

    -- Get user-defined parameters
    local edge_threshold = darktable.preferences.read("artifact_removal", "edge_threshold", "float")
    local smoothing_strength = darktable.preferences.read("artifact_removal", "smoothing_strength", "float")

    darktable.print("Edge threshold: " .. edge_threshold)
    darktable.print("Smoothing strength: " .. smoothing_strength)

    -- Placeholder for artifact removal logic
    darktable.print("Artifact removal logic would run here")

    darktable.print("Artifact removal completed for image: " .. image.filename)
end)

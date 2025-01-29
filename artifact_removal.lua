-- Load Darktable Lua API
local dt = require "darktable"
local df = require "lib/dtutils.file"

-- Plugin metadata
dt.register_event("initialize", function()
    dt.preferences.register("artifact_detection", "edge_threshold", "float",
        "Edge detection threshold", "Threshold for detecting sharpening artifacts (0.0 to 1.0)", 0.1, 0.0, 1.0, 0.01)
    dt.print("Artifact Detection plugin initialized.")
end)

-- Function to create a mask for sharpening artifacts
local function create_artifact_mask(image)
    dt.print("Analyzing image for sharpening artifacts...")

    -- Read the user-defined edge detection threshold
    local edge_threshold = dt.preferences.read("artifact_detection", "edge_threshold", "float")

    -- Create a parametric mask based on edge detection
    local mask = {}
    local width, height = image.width, image.height
    local pixels = image:read_pixel_data() -- Get pixel data from the image

    -- Check if the image has pixel data
    if not pixels then
        dt.print("Error: Unable to read pixel data from the image.")
        return
    end

    -- Simple edge detection (Sobel-like algorithm)
    for y = 2, height - 1 do
        for x = 2, width - 1 do
            local idx = (y - 1) * width + (x - 1)
            local pixel = pixels[idx]

            -- Calculate a simple edge detection value
            local edge_value = math.abs(pixel - pixels[idx - 1]) + math.abs(pixel - pixels[idx + 1])

            -- Apply thresholding
            mask[idx] = (edge_value > edge_threshold) and 1 or 0
        end
    end

    dt.print("Edge detection complete.")

    -- Convert mask into a parametric mask
    image:attach_mask(mask)

    dt.print("Mask created successfully for sharpening artifacts.")
end

-- Register a UI action for the plugin
dt.register_lib("artifact_detection", "Artifact Detection", true, false, {
    [dt.gui.views.lighttable] = {true, false, "analyze_image"}
}, nil, {
    dt.new_widget("button") {
        label = "Analyze for Artifacts",
        clicked_callback = function()
            local image = dt.gui.action_images[1] -- Get the currently selected image
            if not image then
                dt.print("Please select an image.")
                return
            end

            create_artifact_mask(image)
        end
    }
})

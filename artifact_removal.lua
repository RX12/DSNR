local darktable = require "darktable"
local du = require "lib/dtutils"
local df = require "lib/dtutils.file"

-- Plugin metadata
darktable.register_event("initialize", function()
    darktable.preferences.register("artifact_removal", "edge_threshold", "float",
        "Edge detection threshold", "Threshold for detecting sharpening artifacts (0.0 to 1.0)", 0.1, 0.0, 1.0, 0.01)
    darktable.preferences.register("artifact_removal", "smoothing_strength", "float",
        "Smoothing strength", "Strength of artifact smoothing (0.0 to 1.0)", 0.5, 0.0, 1.0, 0.01)
end)

-- Main plugin function
darktable.register_event("post-import", function(event, image)
    -- Check if the plugin is enabled
    if not darktable.preferences.read("artifact_removal", "bool", true) then
        return
    end

    -- Get user-defined parameters
    local edge_threshold = darktable.preferences.read("artifact_removal", "edge_threshold", "float")
    local smoothing_strength = darktable.preferences.read("artifact_removal", "smoothing_strength", "float")

    -- Get the image's pixel data
    local pixels = image:get_pixels()

    -- Apply edge detection and smoothing
    local mask, processed_pixels = remove_artifacts(pixels, edge_threshold, smoothing_strength)

    -- Update the image with the processed pixels
    image:set_pixels(processed_pixels)

    -- Create a parametric mask from the edge detection results
    create_parametric_mask(image, mask)
end)

-- Function to remove artifacts
function remove_artifacts(pixels, edge_threshold, smoothing_strength)
    -- Convert pixels to grayscale for edge detection
    local gray_pixels = grayscale(pixels)

    -- Apply edge detection (e.g., Sobel)
    local edges = detect_edges(gray_pixels, edge_threshold)

    -- Apply smoothing to artifact regions
    local smoothed_pixels = smooth_artifacts(pixels, edges, smoothing_strength)

    -- Return the mask and processed pixels
    return edges, smoothed_pixels
end

-- Convert pixels to grayscale
function grayscale(pixels)
    local gray_pixels = {}
    for i = 1, #pixels, 4 do
        local r, g, b = pixels[i], pixels[i+1], pixels[i+2]
        local gray = 0.299 * r + 0.587 * g + 0.114 * b
        gray_pixels[i] = gray
        gray_pixels[i+1] = gray
        gray_pixels[i+2] = gray
        gray_pixels[i+3] = pixels[i+3] -- Preserve alpha channel
    end
    return gray_pixels
end

-- Detect edges using a simple Sobel filter
function detect_edges(pixels, threshold)
    local edges = {}
    local width, height = darktable.current_image().width, darktable.current_image().height

    for y = 2, height - 1 do
        for x = 2, width - 1 do
            local gx = -pixels[(y-1)*width + (x-1)] + pixels[(y-1)*width + (x+1)] +
                       -2 * pixels[y*width + (x-1)] + 2 * pixels[y*width + (x+1)] +
                       -pixels[(y+1)*width + (x-1)] + pixels[(y+1)*width + (x+1)]

            local gy = -pixels[(y-1)*width + (x-1)] - 2 * pixels[(y-1)*width + x] - pixels[(y-1)*width + (x+1)] +
                       pixels[(y+1)*width + (x-1)] + 2 * pixels[(y+1)*width + x] + pixels[(y+1)*width + (x+1)]

            local magnitude = math.sqrt(gx * gx + gy * gy)
            edges[y*width + x] = (magnitude > threshold) and 1 or 0
        end
    end

    return edges
end

-- Smooth artifact regions using a bilateral filter
function smooth_artifacts(pixels, edges, strength)
    local smoothed_pixels = {}
    local width, height = darktable.current_image().width, darktable.current_image().height

    for y = 2, height - 1 do
        for x = 2, width - 1 do
            if edges[y*width + x] == 1 then
                -- Apply smoothing to artifact regions
                local r, g, b = 0, 0, 0
                local count = 0
                for dy = -1, 1 do
                    for dx = -1, 1 do
                        local idx = (y + dy) * width + (x + dx)
                        r = r + pixels[idx]
                        g = g + pixels[idx + 1]
                        b = b + pixels[idx + 2]
                        count = count + 1
                    end
                end
                smoothed_pixels[y*width + x] = r / count * strength + pixels[y*width + x] * (1 - strength)
                smoothed_pixels[y*width + x + 1] = g / count * strength + pixels[y*width + x + 1] * (1 - strength)
                smoothed_pixels[y*width + x + 2] = b / count * strength + pixels[y*width + x + 2] * (1 - strength)
            else
                -- Preserve non-artifact regions
                smoothed_pixels[y*width + x] = pixels[y*width + x]
                smoothed_pixels[y*width + x + 1] = pixels[y*width + x + 1]
                smoothed_pixels[y*width + x + 2] = pixels[y*width + x + 2]
            end
        end
    end

    return smoothed_pixels
end

-- Function to create a parametric mask
function create_parametric_mask(image, mask)
    local width, height = image.width, image.height

    -- Create a new image for the mask
    local mask_image = darktable.create_image(width, height)

    -- Fill the mask image with the edge detection results
    for y = 1, height do
        for x = 1, width do
            local idx = (y - 1) * width + (x - 1)
            local value = mask[idx] and 1 or 0
            mask_image:set_pixel(x, y, value, value, value, 1)
        end
    end

    -- Attach the mask image to the original image
    image:attach(mask_image)

    -- Use the mask image as a parametric mask
    local mask_module = darktable.gui.libs.mask
    mask_module.add_shape(mask_image, "parametric")
end
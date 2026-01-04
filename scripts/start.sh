#!/bin/bash

# Define paths
COMFY_BASE="/ComfyUI"
MODELS_BASE="$COMFY_BASE/models"
# ‼️ Made the persistence path configurable. Defaults to /workspace, but you can set STORAGE_ROOT env var.
STORAGE_ROOT="${STORAGE_ROOT:-/workspace}"

echo "--- Starting Persistence Manager ---"
echo "Storage Root: $STORAGE_ROOT"

# ‼️ added a check to warn you if you forgot to mount a volume
if [ ! -d "$STORAGE_ROOT" ]; then
  echo "⚠️  WARNING: $STORAGE_ROOT does not exist inside the container!"
  echo "   Your files (outputs, downloaded models) will NOT be saved."
  echo "   Did you forget '-v /my/local/path:$STORAGE_ROOT'?"
  mkdir -p "$STORAGE_ROOT"
fi

# Function to link specific model subfolders
link_model_folder() {
  # e.g., "checkpoints", "loras", "vae"
  FOLDER_NAME=$1

  # Path inside the ephemeral container (e.g., /ComfyUI/models/loras)
  CONTAINER_PATH="$MODELS_BASE/$FOLDER_NAME"

  # Path on your persistent disk (e.g., /workspace/loras)
  PERSISTENT_PATH="$STORAGE_ROOT/$FOLDER_NAME"

  echo "Processing $FOLDER_NAME..."

  # 1. Ensure the container path exists (sanity check)
  if [ ! -d "$CONTAINER_PATH" ]; then
    mkdir -p "$CONTAINER_PATH"
  fi

  # 2. Check if the user already has this folder in storage
  if [ -d "$PERSISTENT_PATH" ]; then
    echo "  Found existing $FOLDER_NAME in storage. Linking..."
    # ‼️ Safety: Only delete the container path if it's NOT a symlink already
    if [ ! -L "$CONTAINER_PATH" ]; then
      rm -rf "$CONTAINER_PATH"
    fi
    ln -sfn "$PERSISTENT_PATH" "$CONTAINER_PATH"

  # 3. If not in storage, move the container's default folder there to seed it
  else
    echo "  No $FOLDER_NAME in storage. Creating it..."
    # ‼️ Move files to storage so they persist, then link back
    mv "$CONTAINER_PATH" "$PERSISTENT_PATH"
    ln -sfn "$PERSISTENT_PATH" "$CONTAINER_PATH"
  fi
}

# Link the standard model folders
link_model_folder "diffusion_models"
link_model_folder "loras"
link_model_folder "vae"
link_model_folder "text_encoders"
# ‼️ Added controlnet as it's commonly used locally
link_model_folder "controlnet"

echo "Processing input/output..."

# Output
# ‼️ Updated to use STORAGE_ROOT
if [ -d "$STORAGE_ROOT/output" ]; then
  rm -rf /ComfyUI/output && ln -sfn "$STORAGE_ROOT/output" /ComfyUI/output
else
  mv /ComfyUI/output "$STORAGE_ROOT/output" && ln -sfn "$STORAGE_ROOT/output" /ComfyUI/output
fi

# Input
if [ -d "$STORAGE_ROOT/input" ]; then
  rm -rf /ComfyUI/input && ln -sfn "$STORAGE_ROOT/input" /ComfyUI/input
else
  mv /ComfyUI/input "$STORAGE_ROOT/input" && ln -sfn "$STORAGE_ROOT/input" /ComfyUI/input
fi

echo "Processing workflows..."

# Define exact paths
WORKFLOW_CONTAINER="/ComfyUI/user/default/workflows"
WORKFLOW_PERSIST="$STORAGE_ROOT/workflows"

# Ensure the parent directory exists in the container
mkdir -p "/ComfyUI/user/default"

# Logic to link workflows
if [ -d "$WORKFLOW_PERSIST" ]; then
  echo "  Found existing workflows in storage. Linking..."
  rm -rf "$WORKFLOW_CONTAINER"
  ln -sfn "$WORKFLOW_PERSIST" "$WORKFLOW_CONTAINER"
else
  echo "  No workflows in storage. Setup new persistence..."
  if [ -d "$WORKFLOW_CONTAINER" ]; then
    mv "$WORKFLOW_CONTAINER" "$WORKFLOW_PERSIST"
  else
    mkdir -p "$WORKFLOW_PERSIST"
  fi
  ln -sfn "$WORKFLOW_PERSIST" "$WORKFLOW_CONTAINER"
fi

echo "--- Launching ComfyUI ---"
cd /ComfyUI
# ‼️ Standard launch. Since you are local, you might want --preview-method auto
python main.py --listen 0.0.0.0 --port 8188

FROM nvidia/cuda:12.8.0-devel-ubuntu24.04

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV VIRTUAL_ENV=/opt/venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH"
ENV STORAGE_ROOT=/workspace

# 1. Install System Dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    git \
    wget \
    rsync \
    libgl1 \
    libglib2.0-0 \
    && python3 -m venv $VIRTUAL_ENV \
    && pip install --no-cache-dir --upgrade pip \
    && rm -rf /var/lib/apt/lists/*

# 2. Install PyTorch Nightly
# RUN pip3 install --no-cache-dir --pre torch torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/cu128
RUN pip3 install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124

# 3. Clone ComfyUI
WORKDIR /
RUN git clone https://github.com/comfyanonymous/ComfyUI.git

# 4. Install ComfyUI Dependencies
WORKDIR /ComfyUI
RUN pip3 install --no-cache-dir -r requirements.txt

# 5. Install Custom Libraries
RUN pip3 install --no-cache-dir \
    # turbodiffusion --no-build-isolation \
    einops \
    loguru \
    omegaconf \
    pandas \
    protobuf \
    gguf-node


# 6. Install Custom Nodes
WORKDIR /ComfyUI/custom_nodes

# Turbo Diffusion
# RUN git clone https://github.com/anveshane/Comfyui_turbodiffusion.git

# ComfyUI Manager
RUN git clone https://github.com/ltdrdata/ComfyUI-Manager.git && \
    pip3 install --no-cache-dir -r ComfyUI-Manager/requirements.txt

RUN git clone https://github.com/calcuis/gguf.git

RUN git clone https://github.com/lrzjason/Comfyui-QwenEditUtils.git

# Video Helper Suite
RUN git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git && \
    pip3 install --no-cache-dir -r ComfyUI-VideoHelperSuite/requirements.txt

# Impact Pack
RUN git clone https://github.com/ltdrdata/ComfyUI-Impact-Pack comfyui-impact-pack && \
    pip3 install --no-cache-dir -r comfyui-impact-pack/requirements.txt

# KJNodes
RUN git clone https://github.com/kijai/ComfyUI-KJNodes.git && \
    pip3 install --no-cache-dir -r ComfyUI-KJNodes/requirements.txt

# LongLook
RUN git clone https://github.com/onerok/comfyUI-LongLook.git

# Rgthree
RUN git clone https://github.com/rgthree/rgthree-comfy.git

RUN git clone https://github.com/ClownsharkBatwing/RES4LYF.git && \
    pip3 install --no-cache-dir -r RES4LYF/requirements.txt

RUN git clone https://github.com/adieyal/comfyui-dynamicprompts.git && \
    pip3 install --no-cache-dir -r comfyui-dynamicprompts/requirements.txt

# Video Utils
RUN git clone https://github.com/saltchicken/ComfyUI-Video-Utils.git

RUN git clone https://github.com/saltchicken/ComfyUI-Local-Loader.git

RUN git clone https://github.com/saltchicken/ComfyUI-Identity-Mixer.git

RUN git clone https://github.com/saltchicken/ComfyUI-Output-Plucker.git

# ComfyScript
RUN git clone https://github.com/Chaoses-Ib/ComfyScript.git && \
    cd ComfyScript && \
    pip3 install --no-cache-dir -e ".[default]"

# 7. Install Your Custom Project
# WORKDIR /opt/custom_runner
# COPY pyproject.toml .
# COPY src ./src
# RUN pip3 install --no-cache-dir .

# 8. Setup Workspace & Start Script
WORKDIR /
# Create default workspace directory
RUN mkdir -p /workspace

COPY scripts/start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 8188

CMD ["/start.sh"]

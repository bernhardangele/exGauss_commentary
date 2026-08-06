FROM ubuntu:latest

RUN apt update -y && apt install -y curl

# Install the Nix package manager (Determinate Systems installer)
RUN curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install linux \
  --extra-conf "sandbox = false" \
  --init none \
  --no-confirm

ENV PATH="${PATH}:/nix/var/nix/profiles/default/bin"

# rstats-on-nix binary cache -> download precompiled packages instead of building from source
RUN mkdir -p /root/.config/nix && \
    echo "substituters = https://cache.nixos.org https://rstats-on-nix.cachix.org" > /root/.config/nix/nix.conf && \
    echo "trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= rstats-on-nix.cachix.org-1:vdiiVgocg6WeJrODIqdprZRUrhi1JzhBnXv7aWI6+F0=" >> /root/.config/nix/nix.conf

WORKDIR /project

# Copy only the pinned Nix environment first so editing the manuscript later
# doesn't invalidate this (slow) build layer.
COPY default.nix install_cmdstan.R ./

# Build the exact, pinned environment from the committed default.nix.
RUN nix-build --cores 2 --max-jobs 1

# Build CmdStan into the image so the container is ready to sample immediately.
RUN nix-shell default.nix --run "Rscript install_cmdstan.R"
ENV CMDSTAN=/root/.cmdstan/cmdstan-2.37.0

# The rest of what's needed to actually render: project config, the .Rprofile
# safety net (blocks install.packages()/keeps R pure inside nix-shell),
# split_qs2.R (recombines the chunked .qs2 model file), the manuscript itself,
# and the real-data example whose fitted model ms.qmd loads.
COPY _quarto.yml .Rprofile split_qs2.R ./
COPY ms ./ms
COPY Angele_et_al_2022 ./Angele_et_al_2022

# Drop into an interactive, reproducible shell by default. Once inside:
#   cd ms && quarto render
# To render in one shot instead without an interactive session, override the
# command at `docker run` time -- see README for the exact invocation.
CMD ["nix-shell", "default.nix", "--pure"]

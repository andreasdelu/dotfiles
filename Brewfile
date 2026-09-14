# Compatibility is not consent: desktop apps require an explicit opt-in.
# bootstrap.sh loads local preferences; direct brew bundle uses process env.
if OS.mac? && ENV["DOTFILES_MACOS_DESKTOP"] == "1"
cask "ghostty"
cask "spotify"
cask "arc"
cask "raycast"
cask "karabiner-elements"
cask "orbstack"
cask "tailscale-app"
cask "linearmouse"
cask "vorssaint"
end

# Formulae
brew "node"
brew "oven-sh/bun/bun"
brew "eza"
brew "gh"
brew "lazygit"
brew "git-delta"
brew "tmux"
brew "neovim"

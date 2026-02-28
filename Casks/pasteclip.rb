cask "pasteclip" do
  version "1.0.0"
  sha256 "a7a800575613811ec7fbcd1cac3a1905844581aab0585026a54d639c93d247f8"

  url "https://github.com/minsang-alt/PasteClip/releases/download/v#{version}/PasteClip-#{version}.dmg"
  name "PasteClip"
  desc "Lightweight clipboard manager for macOS"
  homepage "https://github.com/minsang-alt/PasteClip"

  depends_on macos: ">= :sequoia"

  app "PasteClip.app"

  zap trash: [
    "~/Library/Application Support/PasteClip",
    "~/Library/Containers/com.minsang.PasteClip",
    "~/Library/Preferences/com.minsang.PasteClip.plist",
  ]
end

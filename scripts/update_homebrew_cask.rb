#!/usr/bin/env ruby
# frozen_string_literal: true

path, version, sha256 = ARGV

abort "usage: update_homebrew_cask.rb PATH VERSION SHA256" unless path && version && sha256
abort "invalid cask version: #{version}" unless version.match?(/\A\d+(?:\.\d+)*,\d+\z/)
abort "invalid SHA-256: #{sha256}" unless sha256.match?(/\A[0-9a-f]{64}\z/)

content = File.read(path)

replacements = {
  /^  version ".*"$/ => %(  version "#{version}"),
  /^  sha256 ".*"$/ => %(  sha256 "#{sha256}"),
  /^  url ".*"$/ => '  url "https://github.com/takeshita-0x0201/room/releases/download/' \
                    'v#{version.csv.first}-build.#{version.csv.second}/' \
                    'Room-#{version.csv.first}-build.#{version.csv.second}.zip"'
}

replacements.each do |pattern, replacement|
  matches = content.scan(pattern).length
  abort "expected one #{pattern.inspect} line in #{path}, found #{matches}" unless matches == 1

  content = content.sub(pattern, replacement)
end

File.write(path, content)

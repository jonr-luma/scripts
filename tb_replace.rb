# Set the variables for find/replace
# you can use regular variables here
original_string_or_regex = /Operation::.+\.call\((?!params:)/
replacement_string = "\\&params: "

replacements = [
  { search: /Operation::.+\.call\((?!params:)/, replace: "\\&params: " }
]

# Dir.glob will take care of the recursivity for you
# do not use ~ but rather Dir.home
rbfiles = File.join("#{Dir.home}/Github/luma_app/**", '*.rb')
Dir.glob(rbfiles) do |file_name|
  if File.file? file_name
    text = File.read(file_name)
    file_changes = false
    replacements.each do |replacement|
      s = replacement[:search]
      r = replacement[:replace]
      if replace = text.gsub!(s, r)
        file_changes = true
        text = replace
      end
    end
    File.open(file_name, "w") { |file| file.puts text } if file_changes
  end
end

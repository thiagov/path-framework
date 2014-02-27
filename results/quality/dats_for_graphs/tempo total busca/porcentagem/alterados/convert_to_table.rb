require "pp"

file = ARGV[0]

File.open(file, "r") do |infile|
  algorithms = infile.gets.split(" ")
  algorithms.shift
  if algorithms[0] == "\"D*"
    algorithms.shift
    algorithms[0] = "D* Lite"
  end
  algorithms.unshift(" ")
  data = []
  while map_data = infile.gets
    map_data = map_data.split(" ")
    data << map_data
  end

  header = true
  while !algorithms.empty?
    line = []
    line << algorithms.shift
    data.each do |arr|
      if !header
        num = arr.shift
        num = num.to_f
        num = (num * 100).round(3)
        num = "%.3f" % num
        line << num
      else
        line << arr.shift
      end
    end
    line = line.join(" & ").gsub("\"", "")
    line.concat(" \\\\")
    puts line
    if header
      puts "\\hline"
      header = false
    end
  end
end

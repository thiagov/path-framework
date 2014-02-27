require "pp"

visibility = ARGV[0]

files = ["#{visibility}-look1-porcentagem_sol_otima.dat",
         "#{visibility}-look2-porcentagem_sol_otima.dat",
         "#{visibility}-look3-porcentagem_sol_otima.dat",
         "#{visibility}-look4-porcentagem_sol_otima.dat"]

header = nil

look_one   = {}
look_two   = {}
look_three = {}
look_four  = {}

File.open(files[0], "r") do |file|
  header = file.gets
  while data = file.gets
    data = data.split(" ")
    map = data.shift
    look_one[map] = data
  end
end

File.open(files[1], "r") do |file|
  file.gets
  while data = file.gets
    data = data.split(" ")
    map = data.shift
    look_two[map] = data
  end
end

File.open(files[2], "r") do |file|
  file.gets
  while data = file.gets
    data = data.split(" ")
    map = data.shift
    look_three[map] = data
  end
end

File.open(files[3], "r") do |file|
  file.gets
  while data = file.gets
    data = data.split(" ")
    map = data.shift
    look_four[map] = data
  end
end

maps = look_one.keys

maps.each do |m|
  File.open("per_map/#{m}-#{visibility}.dat", "w") do |outfile|
    outfile.puts header
    outfile.puts "\"Tempo <= 0,025s\" #{look_one[m].join(" ")}"
    outfile.puts "\"Tempo <= 0,050s\" #{look_two[m].join(" ")}"
    outfile.puts "\"Tempo <= 0,075s\" #{look_three[m].join(" ")}"
    outfile.puts "\"Tempo <= 0,100s\" #{look_four[m].join(" ")}"
  end
  #puts "Mapa #{m} com visibility #{visibility}"
  #puts header
  #puts "\"Tempo <= 0,025s\" #{look_one[m].join(" ")}"
  #puts "\"Tempo <= 0,050s\" #{look_two[m].join(" ")}"
  #puts "\"Tempo <= 0,075s\" #{look_three[m].join(" ")}"
  #puts "\"Tempo <= 0,100s\" #{look_four[m].join(" ")}"
end

vis = ARGV[0]

file_one = "#{vis}-look3-porcentagem_sol_otima.dat"
file_ff  = "#{vis}-look4-porcentagem_sol_otima.dat"

File.open(file_one, "r") do |f|
  header = f.gets
  puts header
  File.open(file_ff, "r") do |ff|
    ff.gets
    data = []
    while line_one = f.gets
      line_ff = ff.gets
      line_one  = line_one.split(" ")
      line_ff = line_ff.split(" ")

      out = []
      out << line_one.shift
      line_ff.shift
      line_one.size.times do |x|
        teste = line_one[x].to_f - line_ff[x].to_f
        num = (line_one[x].to_f - line_ff[x].to_f)/line_one[x].to_f
        out << num
      end
      data << out
      puts out.join(" ")
    end
  end
end

#encoding: utf-8

maps = ["arena.map"]#, "den009d.map", "random512-40-2.map", "maze512-32-0.map"]
test_algo = ["lrta", "prta", "lsslrta", "extendedprta"]

test_algo.each do |algorithm|
  maps.each do |sf|
    File.open("#{algorithm}_#{sf}", "w") do |outfile|
      File.open("maps/#{sf}.scen", "r") do |infile|
        version = infile.gets

        cnt = 0
        acc_quality = 0.0
        acc_med_time = 0.0
        acc_max_time = 0.0
        while line = infile.gets
          line = line.delete("\n")
          bucket, map, width, height, sx, sy, gx, gy, optimal = line.split(/\t/)
          sx = sx.to_i
          sy = sy.to_i
          gx = gx.to_i
          gy = gy.to_i
          optimal = optimal.to_f

          result = %x[ruby main.rb #{sy} #{sx} #{gy} #{gx} #{sf} #{algorithm}]
          path_size, med_time, max_time = result.split(" ")

          path_size = path_size.to_f
          path_size = path_size - optimal


          med_time = med_time.to_f
          max_time = max_time.to_f

          acc_quality += path_size
          acc_med_time += med_time
          acc_max_time += max_time
          cnt += 1

          outfile.puts(result)
        end
        outfile.puts("Subotimalidade: #{acc_quality/cnt}")
        outfile.puts("Tempo médio médio: #{acc_med_time/cnt}")
        outfile.puts("Tempo máximo médio: #{acc_max_time/cnt}")
      end
    end
  end
end

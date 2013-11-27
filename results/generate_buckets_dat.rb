dir = ARGV[0]

Dir.foreach(dir) do |infile|
  next if infile == '.' or infile == '..' or infile.split(".")[1] != "csv"

  outfile = infile.gsub(".csv", ".dat")
  outfile = "buckets_#{outfile}"

  File.open("#{dir}/#{infile}", "r") do |i_file|
    File.open("#{dir}/dats/buckets/#{outfile}", "w") do |o_file|
      line = i_file.gets
      g_b = -1
      cnt = 0
      while line = i_file.gets
        n, b, exp, ep, cost, opt, act, tt, mt, mta, maxt, fif, nine = line.gsub("\n", "").split(",")

        if b == g_b
          cnt    += 1
          g_exp  += exp.to_f
          g_ep   += ep.to_f
          g_cost += cost.to_f
          g_opt  += opt.to_f
          g_act  += act.to_f
          g_tt   += tt.to_f
          g_mt   += mt.to_f
          g_mta  += mta.to_f
          g_maxt += maxt.to_f
          g_fif  += fif.to_f
          g_nine += nine.to_f
        else
          if g_b != -1
            o_file.puts("#{g_b} #{g_b} #{g_exp.to_f/cnt.to_f} #{g_ep.to_f/cnt.to_f} #{g_cost.to_f/cnt.to_f} #{g_opt/cnt.to_f} #{g_act/cnt.to_f} #{g_tt/cnt.to_f} #{g_mt/cnt.to_f} #{g_mta/cnt.to_f} #{g_maxt/cnt.to_f} #{g_fif/cnt.to_f} #{g_nine/cnt.to_f}")
          end
          cnt    = 1
          g_b    = b
          g_exp  = exp.to_f
          g_ep   = ep.to_f
          g_cost = cost.to_f
          g_opt  = opt.to_f
          g_act  = act.to_f
          g_tt   = tt.to_f
          g_mt   = mt.to_f
          g_mta  = mta.to_f
          g_maxt = maxt.to_f
          g_fif  = fif.to_f
          g_nine = nine.to_f
        end
      end
    end
  end
end


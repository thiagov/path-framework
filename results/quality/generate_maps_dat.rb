require "pp"

dir = ARGV[0]
files = {}
algos = []

Dir.foreach(dir) do |infile|
  next if infile == '.' or infile == '..' or infile.split(".")[1] != "csv"

  algorithm, map, lookahead = infile.gsub(".csv", "").split("___")
  lookahead = lookahead.split("-")[1]
  algos << algorithm

  if files[map]
    files[map] << infile
  else
    files[map] = [infile]
  end
end

algos = algos.uniq

results = {}
files.each_pair do |k, v|
  results[k] = {}
  v.each do |infile|
    algorithm, map, lookahead = infile.gsub(".csv", "").split("___")
    lookahead = lookahead.split("-")[1]
    File.open("#{dir}/#{infile}", "r") do |i_file|
      line = i_file.gets

      line = i_file.gets
      n, b, exp, ep, cost, opt, act, tt, mt, mta, maxt, fif, nine = line.gsub("\n", "").split(",")
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
      g_actions = ep.to_f * act.to_f

      while line = i_file.gets
        n, b, exp, ep, cost, opt, act, tt, mt, mta, maxt, fif, nine = line.gsub("\n", "").split(",")
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

        g_actions += (ep.to_f * act.to_f)
      end
      #o_file.puts("#{g_b} #{g_b} #{g_exp.to_f/cnt.to_f} #{g_ep.to_f/cnt.to_f} #{g_cost.to_f/cnt.to_f} #{g_opt/cnt.to_f} #{g_act/cnt.to_f} #{g_tt/cnt.to_f} #{g_mt/cnt.to_f} #{g_mta/cnt.to_f} #{g_maxt/cnt.to_f} #{g_fif/cnt.to_f} #{g_nine/cnt.to_f}")
      #TODO: mudar aqui para alterar o que calcular no gráfico!
      results[k][algorithm] = (g_actions)/cnt.to_f
    end
  end
end

pp results


x = dir.split("/").join("-")
outfile = "#{x}-numero-acoes.dat"

File.open("dats_for_graphs/#{outfile}", "w") do |o_file|
  o_file.puts("mapas #{algos.join(" ")}")
  results.each do |k, v|
    out = []
    algos.each do |a|
      out << results[k][a]
    end
    out = out.join(" ")
    o_file.puts("#{k} #{out}")
  end
end

look_hash = {
  "d_lite"  => [[1, 0]], #OK!
  "lrta"    => [[1, 0]], #OK!
  "prta"    => [[1, 0]], #OK!
  "lsslrta" => [[90, 0], [150, 0], [230, 0], [310, 0]], #OK!
  "rtaa"    => [[180, 0], [450, 0], [800, 0], [1100, 0]], #OK
  "tbaa"    => [[180, 0], [420, 0], [660, 0], [880, 0]], #OK!
  "lrta_k"  => [[10000, 0]], #OK!
  "plrta"   => [[140, 100], [270, 100], [480, 100], [700, 100]], #OK!
  "tba"     => [[230, 0], [450, 0], [800, 0], [1100, 0]]
}

map    = ARGV[0]
dir    = ARGV[1]
column = ARGV[2].to_i
look   = ARGV[3].to_i

d_lite  = "\"#{dir}/buckets_d_lite___#{map}___look-1.dat\" using 1:#{column} smooth bezier title \"D* Lite\""
lrta    = "\"#{dir}/buckets_lrta___#{map}___look-1.dat\" using 1:#{column} smooth bezier title \"Lrta\""
prta    = "\"#{dir}/buckets_prta___#{map}___look-1.dat\" using 1:#{column} smooth bezier title \"Prta\""
lsslrta = "\"#{dir}/buckets_lsslrta___#{map}___look-#{look_hash["lsslrta"][look][0]}.dat\" using 1:#{column} smooth bezier title \"LssLrta\""
rtaa    = "\"#{dir}/buckets_rtaa___#{map}___look-#{look_hash["rtaa"][look][0]}.dat\" using 1:#{column} smooth bezier title \"Rtaa\""
tbaa    = "\"#{dir}/buckets_tbaa___#{map}___look-#{look_hash["tbaa"][look][0]}.dat\" using 1:#{column} smooth bezier title \"Tbaa\""
lrta_k  = "\"#{dir}/buckets_lrta_k___#{map}___look-10000.dat\" using 1:#{column} smooth bezier title \"Lrta(k)\""
plrta   = "\"#{dir}/buckets_plrta___#{map}___look-#{look_hash["plrta"][look][0]}.dat\" using 1:#{column} smooth bezier title \"Plrta\""
tba     = "\"#{dir}/buckets_tba___#{map}___look-#{look_hash["tba"][look][0]}.dat\" using 1:#{column} smooth bezier title \"Tba\""

puts "plot #{lsslrta}, #{rtaa}, #{tbaa}, #{plrta}"

#plot "buckets/buckets_lsslrta___arena2___look-90.dat" using 1:5 smooth bezier title "LssLrta"

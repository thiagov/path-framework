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

lsslrta = "\"#{dir}/dats/buckets/buckets_lsslrta___#{map}___look-#{look_hash["lsslrta"][look][0]}.dat\" using 1:#{column} with boxes title \"LssLrta\""
rtaa    = "\"#{dir}/dats/buckets/buckets_rtaa___#{map}___look-#{look_hash["rtaa"][look][0]}.dat\" using ($1+d_width):#{column} with boxes title \"Rtaa\""
tbaa    = "\"#{dir}/dats/buckets/buckets_tbaa___#{map}___look-#{look_hash["tbaa"][look][0]}.dat\" using ($1+(2*d_width)):#{column} with boxes title \"Tbaa\""
lrta_k  = "\"#{dir}/dats/buckets/buckets_lrta_k___#{map}___look-10000.dat\" using ($1+(3*d_width)):#{column} with boxes title \"Lrta(k)\""
plrta   = "\"#{dir}/dats/buckets/buckets_plrta___#{map}___look-#{look_hash["plrta"][look][0]}.dat\" using ($1+(4*d_width)):#{column} with boxes title \"Plrta\""
lrta    = "\"#{dir}/dats/buckets/buckets_lrta___#{map}___look-1.dat\" using ($1+(5*d_width)):#{column} with boxes title \"Lrta\""

puts "plot #{lsslrta}, #{rtaa}, #{tbaa}, #{lrta_k}, #{plrta}"

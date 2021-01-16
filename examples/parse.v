import zztkm.vdotenv as denv

test := denv.parse(true, '.env', '.env.parse')
println(test)
no_names := denv.parse(false)
println(no_names)

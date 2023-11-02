### A Pluto.jl notebook ###
# v0.19.30

using Markdown
using InteractiveUtils

# ╔═╡ c9fe44ec-49d4-11eb-023a-2d887e9efdc5
begin
	using Pkg
	Pkg.activate(".")

	using Revise
	using Tokens
	using SparseArrays
	
end

# ╔═╡ 0c89070c-3de6-11eb-2399-d108ce5e2d47
IndexedToken(:a,(1,2))

# ╔═╡ b893d32a-3de5-11eb-3683-f3ed39735bc7
a = ArrayToken(:a, 3)

# ╔═╡ 556f849e-3de8-11eb-355a-e3a8f9d6ce41
a[1]

# ╔═╡ 67a5440a-49c8-11eb-2878-5b58a5308570
dump(a[1])

# ╔═╡ 9ca7110c-3de7-11eb-201f-113c61f2e00b
ArrayToken(:a, 3,2)

# ╔═╡ e5d088b8-49d1-11eb-0a86-294e136b23fe
-a

# ╔═╡ d7e8237a-3dec-11eb-23bd-75df6d454f9c
x = ScalarToken(:x)

# ╔═╡ e63e5744-3dec-11eb-3129-d187918866da
y = ScalarToken(:y)

# ╔═╡ 668f4ccc-91dc-46fe-bf73-113a6d479055
-x

# ╔═╡ 0640b744-3ded-11eb-2009-2f0fd7b30a1c
z = x+2*y

# ╔═╡ a410b3b6-49c8-11eb-0d18-1d87a0d950b8
dump(z)

# ╔═╡ 490a50ac-49c9-11eb-0a62-fb39771c8b84
v = ArrayToken(:v, 10)

# ╔═╡ bf841c82-49c8-11eb-14a9-69253453f68f
function D1(v, h)
	N = length(v)
	vₓ = similar(v)
	
	vₓ[1] = (v[2] - v[1])/h
	
	for i ∈ 2:N-1
		vₓ[i] = (v[i+1] - v[i-1])/2h
	end
		
	vₓ[N] = (v[N] - v[N-1])/h
	
	return vₓ
end;

# ╔═╡ 6a40dd18-49c9-11eb-22f7-63445b566318
vₓ = D1(v,1)

# ╔═╡ ec1fefcb-b27e-484e-b4c3-53d62110df10
to_matrix(vₓ)

# ╔═╡ Cell order:
# ╠═c9fe44ec-49d4-11eb-023a-2d887e9efdc5
# ╠═0c89070c-3de6-11eb-2399-d108ce5e2d47
# ╠═b893d32a-3de5-11eb-3683-f3ed39735bc7
# ╠═556f849e-3de8-11eb-355a-e3a8f9d6ce41
# ╠═67a5440a-49c8-11eb-2878-5b58a5308570
# ╠═9ca7110c-3de7-11eb-201f-113c61f2e00b
# ╠═e5d088b8-49d1-11eb-0a86-294e136b23fe
# ╠═d7e8237a-3dec-11eb-23bd-75df6d454f9c
# ╠═e63e5744-3dec-11eb-3129-d187918866da
# ╠═668f4ccc-91dc-46fe-bf73-113a6d479055
# ╠═0640b744-3ded-11eb-2009-2f0fd7b30a1c
# ╠═a410b3b6-49c8-11eb-0d18-1d87a0d950b8
# ╠═490a50ac-49c9-11eb-0a62-fb39771c8b84
# ╠═6a40dd18-49c9-11eb-22f7-63445b566318
# ╠═ec1fefcb-b27e-484e-b4c3-53d62110df10
# ╠═bf841c82-49c8-11eb-14a9-69253453f68f

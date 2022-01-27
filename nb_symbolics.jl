### A Pluto.jl notebook ###
# v0.17.7

using Markdown
using InteractiveUtils

# ╔═╡ ebbf00d6-7f38-11ec-19b5-71e05278b855
begin
	using Pkg
	Pkg.activate(".")

	using PlutoUI
	
	using Revise
	using Symbolics
	using SparseArrays
end

# ╔═╡ 80533c95-8bf9-4203-b78f-ce1d4a619855
md"##### Experiments for getting a coefficient matrix using Symbolics.jl"

# ╔═╡ 023979ff-6bea-4b4f-988f-4b9678a34134
@variables v[1:6] 

# ╔═╡ 2a154d2b-ea53-47f4-9d95-b4cf3fdfee1f
v[1] + v[2]

# ╔═╡ dc01e2a9-251c-4e2b-9556-ac320a68127f
typeof(v)

# ╔═╡ d128315c-44ae-4cfd-9269-d0f66c59ef33
md"##### Contents of an expression"

# ╔═╡ b74ce8ff-6b83-4a78-8c8f-2421334f9ead


# ╔═╡ 08a32b95-c57c-4c68-88bb-7baf0ad3b56c
md"##### Inspection methods"

# ╔═╡ ebfbd8a5-0825-4159-bb06-b29a51ea5502
function D1!(vₓ, v, h)
	N = length(v)
	
	vₓ[1] = (v[2] - v[1])/h
	
	for i ∈ 2:N-1
		vₓ[i] = (v[i+1] - v[i-1])/2h
	end
		
	vₓ[N] = (v[N] - v[N-1])/h
	
	return vₓ
end;

# ╔═╡ 1962a611-b36c-4992-998e-c2796185e882
begin
	vₓ = zeros(Num, size(v))
	D1!(vₓ, v,1)
end

# ╔═╡ 2da86fc8-5cb3-4005-a3d4-83e69e423859
vₓ[1]

# ╔═╡ a833dc14-60dc-4c6f-9797-66a10ff4a996
typeof(vₓ[1])

# ╔═╡ 262349ad-afbe-4896-8b28-0ef53b65def5
typeof(vₓ[1].val)

# ╔═╡ cf173eae-a238-4cf1-97ea-b0d9eb032342
arguments(vₓ[1].val)

# ╔═╡ 7039ecf4-b724-4afd-a113-fa61c8eed185
arguments(vₓ[1].val)[1]

# ╔═╡ 58ba049d-57a3-4c2a-9956-58b06ec11372
arguments(arguments(vₓ[1].val)[1])

# ╔═╡ 137a684f-2494-43e6-8b98-d6c742e04a62
arguments(arguments(vₓ[1].val)[1])[1]

# ╔═╡ 825db51c-0d4b-4fe9-aead-3b777e5f95c9
typeof(arguments(arguments(vₓ[1].val)[1])[1])

# ╔═╡ 0f3850e9-56ee-45e2-a829-7b97026a53aa
arguments(arguments(vₓ[1].val)[1])[2]

# ╔═╡ c329a978-891d-4aba-b79b-c2f444033d5d
typeof(arguments(arguments(vₓ[1].val)[1])[2])

# ╔═╡ 3562cb0a-3260-4ecb-81fc-b7bcec892458
arguments(arguments(arguments(vₓ[1].val)[1])[2])

# ╔═╡ 4b1462ee-e2e3-4354-8a53-6dadf7e08559
SymbolicUtils.istree(vₓ[1])

# ╔═╡ Cell order:
# ╠═ebbf00d6-7f38-11ec-19b5-71e05278b855
# ╟─80533c95-8bf9-4203-b78f-ce1d4a619855
# ╠═023979ff-6bea-4b4f-988f-4b9678a34134
# ╠═2a154d2b-ea53-47f4-9d95-b4cf3fdfee1f
# ╠═dc01e2a9-251c-4e2b-9556-ac320a68127f
# ╠═1962a611-b36c-4992-998e-c2796185e882
# ╟─d128315c-44ae-4cfd-9269-d0f66c59ef33
# ╠═2da86fc8-5cb3-4005-a3d4-83e69e423859
# ╠═a833dc14-60dc-4c6f-9797-66a10ff4a996
# ╠═262349ad-afbe-4896-8b28-0ef53b65def5
# ╠═cf173eae-a238-4cf1-97ea-b0d9eb032342
# ╠═7039ecf4-b724-4afd-a113-fa61c8eed185
# ╠═58ba049d-57a3-4c2a-9956-58b06ec11372
# ╠═137a684f-2494-43e6-8b98-d6c742e04a62
# ╠═825db51c-0d4b-4fe9-aead-3b777e5f95c9
# ╠═0f3850e9-56ee-45e2-a829-7b97026a53aa
# ╠═b74ce8ff-6b83-4a78-8c8f-2421334f9ead
# ╠═c329a978-891d-4aba-b79b-c2f444033d5d
# ╠═3562cb0a-3260-4ecb-81fc-b7bcec892458
# ╟─08a32b95-c57c-4c68-88bb-7baf0ad3b56c
# ╠═4b1462ee-e2e3-4354-8a53-6dadf7e08559
# ╠═ebfbd8a5-0825-4159-bb06-b29a51ea5502

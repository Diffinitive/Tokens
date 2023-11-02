### A Pluto.jl notebook ###
# v0.19.30

using Markdown
using InteractiveUtils

# ╔═╡ 2e2c1122-6d9b-4290-93d0-05735626f5f1
begin
	import Pkg
	Pkg.activate(".")
	using Revise
	using Tokens
end

# ╔═╡ 4aa07caf-f552-41db-862e-bcccf71c489f
d⁺ = ArrayToken(:d⁺, 3,3)

# ╔═╡ d9982b8f-6c34-4495-8a23-90754fd63e8c
d⁻ = ArrayToken(:d⁻, 3,3)

# ╔═╡ 50a34761-bbd9-4160-97c2-f0a1e3d5ba47
H = [
	1//2 0 0 0;
	 0   1 0 0;
	 0   0 1 0;
	 0   0 0 1;
]

# ╔═╡ b35b9662-9657-44f9-8f16-6d4820ac718b
D₊ = [
	d⁺ [0;0;1//2];
	[0  0 0 -1//2]
]

# ╔═╡ 8fc666d5-4bad-4f84-b839-6a9e39ef6408
H₊ = [
	1//2 0 0;
	 0   1 0;
	 0   0 1;
]

# ╔═╡ 53ccad1e-fd06-4cca-b5bd-f137516d6c7b
D₋ = [
	d⁻ [0;0;0]
	0  0 -1//2 1//2;
]

# ╔═╡ 47241238-9d64-4c53-953b-4ec1792e0415
H*D₋'

# ╔═╡ Cell order:
# ╠═2e2c1122-6d9b-4290-93d0-05735626f5f1
# ╠═4aa07caf-f552-41db-862e-bcccf71c489f
# ╠═d9982b8f-6c34-4495-8a23-90754fd63e8c
# ╠═50a34761-bbd9-4160-97c2-f0a1e3d5ba47
# ╠═b35b9662-9657-44f9-8f16-6d4820ac718b
# ╠═8fc666d5-4bad-4f84-b839-6a9e39ef6408
# ╠═53ccad1e-fd06-4cca-b5bd-f137516d6c7b
# ╠═47241238-9d64-4c53-953b-4ec1792e0415

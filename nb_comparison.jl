### A Pluto.jl notebook ###
# v0.19.30

using Markdown
using InteractiveUtils

# ╔═╡ de05a6cf-9742-4240-9b8c-ff6ee8f077b9
begin
		using Pkg
		Pkg.activate(".")
		using Revise
	
		using Tokens
	
		using SparseArrays
		using LinearMaps
		
		using Plots
		using Polynomials
end

# ╔═╡ 5217dad3-9064-4107-8be9-9ae6784062ea
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

# ╔═╡ d2ee3ced-ac21-4f7e-bc7e-81e277baf533
md"""
## Calculation times
"""

# ╔═╡ a63b2fe7-fdb8-49dd-9827-bddcac0e98e7
md"""
### LinearMaps
"""

# ╔═╡ 6eeb3815-af44-4f07-afe3-1bb51009fa92
begin
	Ns_lm = 2:10:4000

	sparse(LinearMap(v->D1(v,1), Ns_lm[1])) # Compilation
	
	runtimes_lm = map(Ns_lm) do n
		@elapsed sparse(LinearMap(v->D1(v,1), n))
	end
end;

# ╔═╡ 97bd9e6b-c8b2-4a02-a71a-af66d92dfc41
md"""
### Tokens
"""

# ╔═╡ a80056a5-641b-4857-813d-76429e3a7b9c
begin
	Ns_tok = 2:10:8000

	to_matrix(D1(ArrayToken(:v, Ns_tok[1]),1)) # Compilation

	runtimes_tok = map(Ns_tok) do n
		@elapsed to_matrix(D1(ArrayToken(:v, n),1))
	end
end;

# ╔═╡ 98deccb2-cfe8-459b-be1f-6b480d5dec60
md"""
### Results
"""

# ╔═╡ d18db711-4a8f-461f-80ca-32e85de1b71f
let
	p_lm = fit(Ns_lm,runtimes_lm, 2)
	p_tok = fit(Ns_tok,runtimes_tok, 1)
	
	plot(;
		legend=false,
		xlabel="N",
		ylabel="t [s]",
	)

	plot!(Ns_lm,runtimes_lm)
	plot!(Ns_lm,p_lm.(Ns_lm))

	plot!(Ns_tok,runtimes_tok)
	plot!(Ns_tok,p_tok.(Ns_tok))
end

# ╔═╡ Cell order:
# ╠═de05a6cf-9742-4240-9b8c-ff6ee8f077b9
# ╠═5217dad3-9064-4107-8be9-9ae6784062ea
# ╟─d2ee3ced-ac21-4f7e-bc7e-81e277baf533
# ╟─a63b2fe7-fdb8-49dd-9827-bddcac0e98e7
# ╠═6eeb3815-af44-4f07-afe3-1bb51009fa92
# ╟─97bd9e6b-c8b2-4a02-a71a-af66d92dfc41
# ╠═a80056a5-641b-4857-813d-76429e3a7b9c
# ╟─98deccb2-cfe8-459b-be1f-6b480d5dec60
# ╠═d18db711-4a8f-461f-80ca-32e85de1b71f

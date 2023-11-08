### A Pluto.jl notebook ###
# v0.19.27

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

# ╔═╡ 622cb349-7935-44f2-aa5f-57e1fa59b213
function to_matrix_linearmap(f, n, m)
	return sparse(LinearMap(f, n))
end

# ╔═╡ 98deccb2-cfe8-459b-be1f-6b480d5dec60
md"""
### Results
"""

# ╔═╡ c1741e59-dece-4a8d-9cc8-b52fe39de106
begin
	f = v->D1(v,1)

	cases = [
		(
			name="LinearMaps",
			p = 2,
			p_name = "P₂",
			Ns = 2:10:4000,
			converter = to_matrix_linearmap,
		),
		(
			name="Tokens",
			p = 1,
			p_name = "P₁",
			Ns = 2:10:8000,
			converter = to_matrix,
		),
	]

	results = map(cases) do case
		case.converter(f, 2,2) # compilation?
		runtimes = map(case.Ns) do n
			@elapsed case.converter(f, n,n)
		end
			
		(
			name = case.name,
			Ns = case.Ns,
			p = case.p,
			p_name = case.p_name,
			runtimes = runtimes
		)
	end
end

# ╔═╡ 9cb08acc-ac34-4cb4-aafb-f0165e7b9ad8
let
	plt = plot(;
		title="Matrix fetch time comparison",
		xlabel="N",
		ylabel="t [s]",
		minorgrid=true,
	)

	for (i,r) ∈ enumerate(results)
		p = fit(r.Ns,r.runtimes, r.p)
		scatter!(r.Ns, r.runtimes,
			label=r.name,
			markerstrokecolor=i,
			markercolor = i,
			markersize=1,
		)
		plot!(r.Ns,p.(r.Ns);
			label=r.p_name,
			linestyle=:dash,
			linewidth=3,
			color=i,
		)
	end

	plt
end

# ╔═╡ Cell order:
# ╠═de05a6cf-9742-4240-9b8c-ff6ee8f077b9
# ╠═5217dad3-9064-4107-8be9-9ae6784062ea
# ╟─d2ee3ced-ac21-4f7e-bc7e-81e277baf533
# ╟─a63b2fe7-fdb8-49dd-9827-bddcac0e98e7
# ╠═622cb349-7935-44f2-aa5f-57e1fa59b213
# ╟─98deccb2-cfe8-459b-be1f-6b480d5dec60
# ╠═c1741e59-dece-4a8d-9cc8-b52fe39de106
# ╠═9cb08acc-ac34-4cb4-aafb-f0165e7b9ad8

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
function D1alt(v, h)
	N = length(v)
	vₓ = similar(v)
	
	vₓ[1] = (v[2] - v[1])/h
	
	for i ∈ 2:N-1
		vₓ[i] = (v[i+1] - v[i-1])/2h
	end
		
	vₓ[N] = (v[N] - v[N-1])/h
	
	return vₓ
end; # Is this faster?

# ╔═╡ ad33d948-ff32-44d9-89d2-5aa560b9a7fc
function D1(v, i, h)
	if i == 1
		return (v[2] - v[1])/h
	end

	if i == length(v)
		return (v[end] - v[end-1])/h
	end

	return (v[i+1] - v[i-1])/2h
end;

# ╔═╡ 5ef1bcee-49bd-4619-9f3d-8c70fef9cf93
function D1!(v′, v, h)
	for i ∈ 1:length(v)
		v′[i] = @inline D1(v,i,h)
	end
end

# ╔═╡ cfb98682-74b8-4819-b856-b63863552513
# D1(v,h) = [D1(v,i,h) for i ∈ 1:length(v)]
function D1(v,h)
	v′ = similar(v)
	
	@inline D1!(v′,v,h)

	return v′
end

# ╔═╡ c33a6b33-17a5-4e16-8f98-ef0082203874
function laplace(v,i,h)
   if i == 1 || i == length(v)
	   return zero(eltype(v))
   end
   
   return (v[i-1]-2v[i]+v[i+1])/h^2
end

# ╔═╡ 7814eed6-486d-44d5-aa73-3f79128ddc62
laplace(v,h) = [laplace(v,i,h) for i ∈ 1:length(v)]

# ╔═╡ 14c41a58-c093-4716-96ce-dcd89fd6f08a
function laplace!(∇²v, v, h)
	for i ∈ 1:length(v)
		∇²v[i] = laplace(v,i,h)
	end
end

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

# ╔═╡ 6eeb3815-af44-4f07-afe3-1bb51009fa92
begin
	Ns_lm = 2:10:4000

	to_matrix_linearmap(v->D1(v,1), 2, 2) # Compilation
	
	runtimes_lm = map(Ns_lm) do n
		@elapsed to_matrix_linearmap(v->D1(v,1),n, n)
	end
end;

# ╔═╡ 97bd9e6b-c8b2-4a02-a71a-af66d92dfc41
md"""
### Tokens
"""

# ╔═╡ a80056a5-641b-4857-813d-76429e3a7b9c
begin
	Ns_tok = 2:10:8000
	
	to_matrix(v->D1(v,1),2,2) # Compilation

	runtimes_tok = map(Ns_tok) do n
		@elapsed to_matrix(v->D1(v,1),n,n)
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
		title="Matrix fetch time comparison",
		xlabel="N",
		ylabel="t [s]",
		minorgrid=true,
	)

	scatter!(Ns_lm, runtimes_lm,
		label="LinearMaps",
		markerstrokecolor=1,
		markercolor = 1,
		markersize=1,
	)
	plot!(Ns_lm,p_lm.(Ns_lm);
		label="P₂",
		linestyle=:dash,
		linewidth=3,
		color=1,
	)

	scatter!(Ns_tok,runtimes_tok;
		label="Tokens",
		markerstrokecolor = 2,
		markercolor = 2,
		markersize=1,
	)
	plot!(Ns_tok,p_tok.(Ns_tok);
		label="P₁",
		linestyle=:dash,
		linewidth=3,
		color=2,
	)
end

# ╔═╡ Cell order:
# ╠═de05a6cf-9742-4240-9b8c-ff6ee8f077b9
# ╠═5217dad3-9064-4107-8be9-9ae6784062ea
# ╠═ad33d948-ff32-44d9-89d2-5aa560b9a7fc
# ╠═cfb98682-74b8-4819-b856-b63863552513
# ╠═5ef1bcee-49bd-4619-9f3d-8c70fef9cf93
# ╠═c33a6b33-17a5-4e16-8f98-ef0082203874
# ╠═7814eed6-486d-44d5-aa73-3f79128ddc62
# ╠═14c41a58-c093-4716-96ce-dcd89fd6f08a
# ╟─d2ee3ced-ac21-4f7e-bc7e-81e277baf533
# ╟─a63b2fe7-fdb8-49dd-9827-bddcac0e98e7
# ╠═622cb349-7935-44f2-aa5f-57e1fa59b213
# ╠═6eeb3815-af44-4f07-afe3-1bb51009fa92
# ╟─97bd9e6b-c8b2-4a02-a71a-af66d92dfc41
# ╠═a80056a5-641b-4857-813d-76429e3a7b9c
# ╟─98deccb2-cfe8-459b-be1f-6b480d5dec60
# ╠═d18db711-4a8f-461f-80ca-32e85de1b71f

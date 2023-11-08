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
		using Symbolics
		
		using Plots
		using Polynomials
end

# ╔═╡ 0bd9c083-a3f0-4168-9d7f-2d6b1210db05
md"""
## Operators
"""

# ╔═╡ 14599617-c539-4ef3-b903-314c057bb38a
md"""
### D1
"""

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

# ╔═╡ cfb98682-74b8-4819-b856-b63863552513
function D1(v,h)
	v′ = similar(v)
	
	@inline D1!(v′,v,h)

	return v′
end

# ╔═╡ 5ef1bcee-49bd-4619-9f3d-8c70fef9cf93
function D1!(v′, v, h)
	for i ∈ 1:length(v)
		v′[i] = @inline D1(v,i,h)
	end
end

# ╔═╡ 3ba18a4d-14a7-45f4-802a-bb9e39652728
md"""
### Laplace
"""

# ╔═╡ c33a6b33-17a5-4e16-8f98-ef0082203874
function laplace(v,i,h)
   if i == 1 || i == length(v)
	   return zero(eltype(v))
   end
   
   return (v[i-1]-2v[i]+v[i+1])/h^2
end

# ╔═╡ 6c039587-0a43-47f1-9523-d8143fd95ba7
function laplace(v,h)
	∇²v = similar(v)
	
	@inline laplace!(∇²v,v,h)

	return ∇²v
end

# ╔═╡ 14c41a58-c093-4716-96ce-dcd89fd6f08a
function laplace!(∇²v, v, h)
	for i ∈ 1:length(v)
		∇²v[i] = @inline laplace(v,i,h)
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

# ╔═╡ 6f35320c-1840-4ebc-8c4f-8534b8191bcd
md"""
### Symbolics
"""

# ╔═╡ 5b1cbeb4-ce2e-4566-b649-67b3fddd9fb2
function sparsemap(f, A::SparseMatrixCSC{Tv,Ti}) where {Tv, Ti}
    nzval = map(f,nonzeros(A))

    return SparseMatrixCSC{eltype(nzval),Ti}(A.n,A.m,copy(A.colptr),copy(A.rowval), nzval)
end;

# ╔═╡ 820a78b4-469c-4c0f-bdc7-ef5a0cef5b52
function to_matrix_symbolics(f, n, m)
    @variables v[1:m]

    fv = f(v)
    
    return sparsemap(Symbolics.sparsejacobian(fv,v)) do e
        e.val
    end
end

# ╔═╡ 12c278f2-c4fc-4030-91e0-bd420e86218b
to_matrix_symbolics(v->D1(v,1),10,10)

# ╔═╡ 98deccb2-cfe8-459b-be1f-6b480d5dec60
md"""
### Results
"""

# ╔═╡ c1741e59-dece-4a8d-9cc8-b52fe39de106
begin
	cases = [
		(
			name="LinearMaps",
			p = 2,
			p_name = "P₂",
			Ns = 2:10:4000,
			converter = to_matrix_linearmap,
			f = v->D1(v,1),
		),
		(
			name="Tokens",
			p = 1,
			p_name = "P₁",
			Ns = 2:10:8000,
			converter = to_matrix,
			f = v->D1(v,1),
		),
	]

	results = map(cases) do case
		case.converter(case.f, 2,2) # compilation?
		runtimes = map(case.Ns) do n
			@elapsed case.converter(case.f, n,n)
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
# ╟─0bd9c083-a3f0-4168-9d7f-2d6b1210db05
# ╟─14599617-c539-4ef3-b903-314c057bb38a
# ╠═ad33d948-ff32-44d9-89d2-5aa560b9a7fc
# ╠═5ef1bcee-49bd-4619-9f3d-8c70fef9cf93
# ╠═cfb98682-74b8-4819-b856-b63863552513
# ╟─3ba18a4d-14a7-45f4-802a-bb9e39652728
# ╠═c33a6b33-17a5-4e16-8f98-ef0082203874
# ╠═14c41a58-c093-4716-96ce-dcd89fd6f08a
# ╠═6c039587-0a43-47f1-9523-d8143fd95ba7
# ╟─d2ee3ced-ac21-4f7e-bc7e-81e277baf533
# ╟─a63b2fe7-fdb8-49dd-9827-bddcac0e98e7
# ╠═622cb349-7935-44f2-aa5f-57e1fa59b213
# ╠═6f35320c-1840-4ebc-8c4f-8534b8191bcd
# ╠═820a78b4-469c-4c0f-bdc7-ef5a0cef5b52
# ╠═5b1cbeb4-ce2e-4566-b649-67b3fddd9fb2
# ╠═12c278f2-c4fc-4030-91e0-bd420e86218b
# ╟─98deccb2-cfe8-459b-be1f-6b480d5dec60
# ╠═c1741e59-dece-4a8d-9cc8-b52fe39de106
# ╠═9cb08acc-ac34-4cb4-aafb-f0165e7b9ad8

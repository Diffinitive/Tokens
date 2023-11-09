### A Pluto.jl notebook ###
# v0.19.32

using Markdown
using InteractiveUtils

# ╔═╡ de05a6cf-9742-4240-9b8c-ff6ee8f077b9
begin
		using Pkg
		Pkg.activate(".")
		using Revise

		using PlutoUI
	
		using Tokens
	
		using SparseArrays
		using LinearMaps
		using Symbolics
		
		using Plots
		using Polynomials
end

# ╔═╡ dae0ff68-37f8-4f25-9c88-5535cfe24dab
md"""
# Comparison of different matrix conversion functions
"""

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

# ╔═╡ 7b043c57-96ab-4349-9ae7-c517dc7ad981
md"""
### Local average
"""

# ╔═╡ 09d6c9b2-a1ae-4bce-a6dc-933c71dbc1c7
function localaverage(v,i,R)
	N = length(v)
	
	if i-R < 1
		Is = range(1, 2R+1)
	elseif i+R > N
		Is = range(N-2R, N)
	else
		Is = range(i-R, i+R)
	end

	return sum(@view v[Is])/(2R+1)
end

# ╔═╡ 7d95c579-02c6-499e-8085-cf0349ad234d
function localaverage(v,R)
	Σv = similar(v)
	
	@inline localaverage!(Σv,v,R)

	return Σv
end

# ╔═╡ 2af3174d-86dd-4fb4-83f8-d280763e7d36
function localaverage!(Σv, v, R)
	for i ∈ 1:length(v)
		Σv[i] = @inline localaverage(v,i,R)
	end
end

# ╔═╡ d2ee3ced-ac21-4f7e-bc7e-81e277baf533
md"""
## Conversion functions
"""

# ╔═╡ 6f939569-ac7a-407d-973e-c7d37c527c77
md"""
### Tokens
The function `to_matrix` is defined in the subpackage `Tokens`.
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
	
    fv = f(collect(v))
    
    return sparsemap(Symbolics.sparsejacobian(fv,v)) do e
        e.val
    end
end

# ╔═╡ 98deccb2-cfe8-459b-be1f-6b480d5dec60
md"""
## Results
"""

# ╔═╡ 8f1377a1-f857-4387-955c-d6b6f5412642
md"""
### Different sizes
"""

# ╔═╡ c1741e59-dece-4a8d-9cc8-b52fe39de106
begin
	size_cases = [
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
		# (
		# 	name="Symbolics",
		# 	p = 1,
		# 	p_name = "P₁",
		# 	Ns = 2:10:50,
		# 	converter = to_matrix_symbolics,
		# 	f = v->D1(v,1),
		# ),
	]

	size_results = map(size_cases) do case
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
		title="Conversion of D1",
		xlabel="N",
		ylabel="t [s]",
		minorgrid=true,
	)

	for (i,r) ∈ enumerate(size_results)
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

# ╔═╡ 502e4207-69b2-47b6-b976-a5185a0ce1d6
md"""
### Different bandwidths
"""

# ╔═╡ 4dd70d83-36d2-459c-a4a4-90c274689325
begin
	N_bandwidth_comparison = 1000
	bandwidth_cases = [
		(
			name="LinearMaps",
			p = 0,
			p_name = "P₀",
			Rs = 2:50,
			converter = to_matrix_linearmap,
		),
		(
			name="Tokens",
			p = 2,
			p_name = "P₂",
			Rs = 2:100,
			converter = to_matrix,
		),
	]

	bandwidth_results = map(bandwidth_cases) do case
		runtimes = map(case.Rs) do R
			f(v) = localaverage(v, R)
			@elapsed case.converter(f, N_bandwidth_comparison,N_bandwidth_comparison)
		end
			
		(
			name = case.name,
			Rs = case.Rs,
			p = case.p,
			p_name = case.p_name,
			runtimes = runtimes,
		)
	end
end

# ╔═╡ a2481e07-a0de-49e3-83f1-ab248f1f5a8f
let
	plt = plot(;
		title = "N = $N_bandwidth_comparison",
		xlabel="Bandwidth",
		ylabel="t [s]",
		minorgrid=true,
	)

	for (i,r) ∈ enumerate(bandwidth_results)
		Ns = 2 .*r.Rs .+ 1
		
		p = fit(Ns,r.runtimes, r.p)
		scatter!(Ns, r.runtimes,
			label=r.name,
			markerstrokecolor=i,
			markercolor = i,
			markersize=2,
		)
		plot!(Ns,p.(Ns);
			label=r.p_name,
			linestyle=:dash,
			linewidth=3,
			color=i,
		)
	end

	plt
end

# ╔═╡ 44770c58-b36a-46d0-b599-0321cfcf24bf
md"""
### Different powers
"""

# ╔═╡ 0a3f2fe9-b987-4628-897d-13858dcbc344
md"""
## Appendix
"""

# ╔═╡ dcdbeeb4-817a-4136-a3e8-27a2d71b4b07
PlutoUI.TableOfContents()

# ╔═╡ Cell order:
# ╟─dae0ff68-37f8-4f25-9c88-5535cfe24dab
# ╟─0bd9c083-a3f0-4168-9d7f-2d6b1210db05
# ╟─14599617-c539-4ef3-b903-314c057bb38a
# ╠═ad33d948-ff32-44d9-89d2-5aa560b9a7fc
# ╠═5ef1bcee-49bd-4619-9f3d-8c70fef9cf93
# ╠═cfb98682-74b8-4819-b856-b63863552513
# ╟─3ba18a4d-14a7-45f4-802a-bb9e39652728
# ╠═c33a6b33-17a5-4e16-8f98-ef0082203874
# ╠═14c41a58-c093-4716-96ce-dcd89fd6f08a
# ╠═6c039587-0a43-47f1-9523-d8143fd95ba7
# ╟─7b043c57-96ab-4349-9ae7-c517dc7ad981
# ╠═09d6c9b2-a1ae-4bce-a6dc-933c71dbc1c7
# ╠═2af3174d-86dd-4fb4-83f8-d280763e7d36
# ╠═7d95c579-02c6-499e-8085-cf0349ad234d
# ╟─d2ee3ced-ac21-4f7e-bc7e-81e277baf533
# ╟─6f939569-ac7a-407d-973e-c7d37c527c77
# ╟─a63b2fe7-fdb8-49dd-9827-bddcac0e98e7
# ╠═622cb349-7935-44f2-aa5f-57e1fa59b213
# ╟─6f35320c-1840-4ebc-8c4f-8534b8191bcd
# ╠═820a78b4-469c-4c0f-bdc7-ef5a0cef5b52
# ╠═5b1cbeb4-ce2e-4566-b649-67b3fddd9fb2
# ╟─98deccb2-cfe8-459b-be1f-6b480d5dec60
# ╟─8f1377a1-f857-4387-955c-d6b6f5412642
# ╟─9cb08acc-ac34-4cb4-aafb-f0165e7b9ad8
# ╟─c1741e59-dece-4a8d-9cc8-b52fe39de106
# ╟─502e4207-69b2-47b6-b976-a5185a0ce1d6
# ╟─a2481e07-a0de-49e3-83f1-ab248f1f5a8f
# ╟─4dd70d83-36d2-459c-a4a4-90c274689325
# ╟─44770c58-b36a-46d0-b599-0321cfcf24bf
# ╟─0a3f2fe9-b987-4628-897d-13858dcbc344
# ╠═de05a6cf-9742-4240-9b8c-ff6ee8f077b9
# ╠═dcdbeeb4-817a-4136-a3e8-27a2d71b4b07

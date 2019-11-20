import Test.@test
import Test.@test_throws

abstract type ExprC end

struct NumC <: ExprC
    n::Number
end

struct IdC <: ExprC
    s::String
end

struct StringC <: ExprC
    s::String
end

struct AppC <: ExprC
    f::ExprC
    args::Array{ExprC}
end

struct LamC <: ExprC
    args::Array{String}
    body::ExprC
end

abstract type Value end

struct PrimOpV <: Value
    f::Function
end

struct NumV <: Value
    n::Number
end

struct StringV <: Value
    s::String
end

struct ClosV <: Value
    args::Array{String}
    body::ExprC
    env::Dict{String, Value}
end

#top-env = Dict([])

# interprets a given expression
function interp(e::ExprC, env::Dict{String, Value})::Value
    if typeof(e) == NumC
        return NumV(e.n)
    elseif typeof(e) == IdC
        return lookup(e.s, env)
    elseif typeof(e) == StringC
        return StringV(e.s)
    elseif typeof(e) == LamC
        return ClosV(e.args, e.body, env)
    end
end

# looks up
function lookup(i::String, env::Dict{String, Value})::Value
    if haskey(env, i)
        return get(env, i, -1)
    else
        error("RGME: lookup failed")
    end
end

# primitive adding function
function myadd(args::Array{Value})::Value
    if length(args) == 2
        if typeof(args[1]) == NumV && typeof(args[2]) == NumV
            return NumV(args[1].n + args[2].n)
        else
            error("RGME: invalid addition input")
        end
    else
        error("RGME: wrong number of arguments")
    end
end


# test cases:
testEnv = Dict([("x", NumV(2)), ("+", PrimOpV(myadd))])
@test lookup("x", testEnv) == NumV(2)
@test_throws ErrorException lookup("y", testEnv)

@test interp(NumC(3), testEnv) == NumV(3)
@test interp(IdC("x"), testEnv) == NumV(2)
@test interp(StringC("hi"), testEnv) == StringV("hi")

res = interp(LamC(["a", "b"], NumC(2)), testEnv)
@test typeof(res) == ClosV && res.args == ["a", "b"] && res.body == NumC(2) && res.env == testEnv

@test myadd(Array{Value}([NumV(3), NumV(2)])) == NumV(5)
@test_throws ErrorException myadd(Array{Value}([]))
@test_throws ErrorException myadd([StringV("hi"), NumV(0)])

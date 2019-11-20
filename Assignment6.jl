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

struct IfC <: ExprC
    cond::ExprC
    t::ExprC
    f::ExprC
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

struct BoolV <: Value
    b::Bool
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
    elseif typeof(e) == IfC
        c = interp(e.cond, env)
        if typeof(c) != BoolV
            error("RGME: if statement conditional must evaluate to boolean")
        end
        if c.b == true
            return interp(e.t, env)
        else
            return interp(e.f, env)
        end
    elseif typeof(e) == AppC
        func = interp(e.f, env)
        args = Array{Value}(map(x -> interp(x, env), e.args))
        if typeof(func) == PrimOpV
            return func.f(args)
        elseif typeof(func) == ClosV
            return interp(func.body, bind(func.args, args, env))
        else
            error("RGME: attempted to apply value")
        end
    end
end

# looks up value in environment
function lookup(i::String, env::Dict{String, Value})::Value
    if haskey(env, i)
        return get(env, i, -1)
    else
        error("RGME: lookup failed")
    end
end

# binds values to environment
function bind(what::Array{String}, values::Array{Value}, env::Dict{String, Value})::Dict{String, Value}
    if length(what) != length(values)
        error("RGME: Invalid function arrity")
    end

    e = env
    for (index, key) in enumerate(what)
        e[key] = values[index]
    end

    return e
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
testEnv = Dict([("x", NumV(2)), ("+", PrimOpV(myadd)), ("true", BoolV(true))])
@test lookup("x", testEnv) == NumV(2)
@test_throws ErrorException lookup("y", testEnv)

@test bind(["a", "b"], Array{Value}([NumV(4), NumV(5)]), Dict{String, Value}()) == Dict([("a", NumV(4)), ("b", NumV(5))])
@test_throws ErrorException bind(["a"], Array{Value}([]), Dict{String, Value}())

@test interp(NumC(3), testEnv) == NumV(3)
@test interp(IdC("x"), testEnv) == NumV(2)
@test interp(StringC("hi"), testEnv) == StringV("hi")
@test interp(AppC(IdC("+"), Array{ExprC}([NumC(4), NumC(5)])), testEnv) == NumV(9)
@test interp(AppC(LamC(["x"], IdC("x")), Array{ExprC}([NumC(4)])), testEnv) == NumV(4)
@test interp(IfC(IdC("true"), NumC(0), NumC(1)), testEnv) == NumV(0)
res = interp(LamC(["a", "b"], NumC(2)), testEnv)
@test typeof(res) == ClosV && res.args == ["a", "b"] && res.body == NumC(2) && res.env == testEnv
@test_throws ErrorException interp(AppC(NumC(4), Array{ExprC}([])), testEnv)
@test_throws ErrorException interp(IfC(NumC(0), NumC(0), NumC(1)), testEnv)

@test myadd(Array{Value}([NumV(3), NumV(2)])) == NumV(5)
@test_throws ErrorException myadd(Array{Value}([]))
@test_throws ErrorException myadd([StringV("hi"), NumV(0)])

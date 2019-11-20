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


#top-env = Dict([])

# e (input) is of type ExprC and the output is of type Value
# interprets a given expression
function interp(e, env)
    if typeof(e) == NumC
        return NumV(e.n)
    elseif typeof(e) == IdC
        return lookup(e.s, env)
    elseif typeof(e) == StringC
        return StringV(e.s)
    end
end

# i (input) is of type String and the output is of type Value
# looks up
function lookup(i, env)
    if haskey(env, i)
        return get(env, i, -1)
    else
        error("RGME: lookup failed")
    end
end

# args (input) is of type Array{Value}
# primitive adding function
function myadd(args)
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

@test myadd([NumV(3), NumV(2)]) == NumV(5)
@test_throws ErrorException myadd([])
@test_throws ErrorException myadd([StringV("hi"), NumV(0)])
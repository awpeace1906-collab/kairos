import Foundation

// Tiny safe arithmetic evaluator for calculator `formula` expressions.
// Mirrors web/src/lib/expr.js exactly. No NSExpression, no eval.
// Grammar: numbers, variable names, + - * / ^, unary -, parentheses, and a
// whitelisted set of functions.

enum ExpressionError: Error, CustomStringConvertible {
    case syntax(String)
    case unknownVariable(String)
    case unknownFunction(String)
    var description: String {
        switch self {
        case .syntax(let s): return "syntax error: \(s)"
        case .unknownVariable(let v): return "unknown variable \"\(v)\""
        case .unknownFunction(let f): return "unknown function \"\(f)\""
        }
    }
}

struct Expression {
    private enum Token: Equatable {
        case number(Double)
        case ident(String)
        case op(Character)   // + - * / ^ ( ) ,
    }

    static func evaluate(_ source: String, scope: [String: Double]) throws -> Double {
        let tokens = try tokenize(source)
        var parser = Parser(tokens: tokens, scope: scope, source: source)
        let value = try parser.parseExpr()
        guard parser.atEnd else { throw ExpressionError.syntax("trailing tokens in: \(source)") }
        return value
    }

    private static let funcs: [String: ([Double]) -> Double] = [
        "sqrt": { Foundation.sqrt($0[0]) },
        "cbrt": { Foundation.cbrt($0[0]) },
        "abs":  { Swift.abs($0[0]) },
        "ln":   { Foundation.log($0[0]) },
        "log10": { Foundation.log10($0[0]) },
        "exp":  { Foundation.exp($0[0]) },
        "min":  { $0.min() ?? .nan },
        "max":  { $0.max() ?? .nan },
        "round": { ($0[0]).rounded() },
        "floor": { ($0[0]).rounded(.down) },
        "ceil":  { ($0[0]).rounded(.up) },
    ]

    private static func tokenize(_ s: String) throws -> [Token] {
        var out: [Token] = []
        let chars = Array(s)
        var i = 0
        while i < chars.count {
            let c = chars[i]
            if c == " " || c == "\t" || c == "\n" { i += 1; continue }
            if "+-*/^(),".contains(c) { out.append(.op(c)); i += 1; continue }
            if c.isNumber || c == "." {
                var j = i + 1
                while j < chars.count, chars[j].isNumber || chars[j] == "." || chars[j] == "e" || chars[j] == "E" ||
                      ((chars[j] == "+" || chars[j] == "-") && (chars[j-1] == "e" || chars[j-1] == "E")) {
                    j += 1
                }
                guard let n = Double(String(chars[i..<j])) else { throw ExpressionError.syntax("bad number in: \(s)") }
                out.append(.number(n)); i = j; continue
            }
            if c.isLetter || c == "_" {
                var j = i + 1
                while j < chars.count, chars[j].isLetter || chars[j].isNumber || chars[j] == "_" { j += 1 }
                out.append(.ident(String(chars[i..<j]))); i = j; continue
            }
            throw ExpressionError.syntax("bad character \"\(c)\" in: \(s)")
        }
        return out
    }

    private struct Parser {
        let tokens: [Token]
        let scope: [String: Double]
        let source: String
        var pos = 0
        var atEnd: Bool { pos >= tokens.count }
        func peek() -> Token? { pos < tokens.count ? tokens[pos] : nil }
        mutating func next() -> Token? { defer { pos += 1 }; return peek() }
        mutating func expect(_ ch: Character) throws {
            guard case .op(let c)? = peek(), c == ch else { throw ExpressionError.syntax("expected \"\(ch)\" in: \(source)") }
            pos += 1
        }

        mutating func parseExpr() throws -> Double { try parseAddSub() }

        mutating func parseAddSub() throws -> Double {
            var left = try parseMulDiv()
            while case .op(let c)? = peek(), c == "+" || c == "-" {
                pos += 1
                let right = try parseMulDiv()
                left = (c == "+") ? left + right : left - right
            }
            return left
        }
        mutating func parseMulDiv() throws -> Double {
            var left = try parsePow()
            while case .op(let c)? = peek(), c == "*" || c == "/" {
                pos += 1
                let right = try parsePow()
                left = (c == "*") ? left * right : left / right
            }
            return left
        }
        mutating func parsePow() throws -> Double {
            let left = try parseUnary()
            if case .op(let c)? = peek(), c == "^" {
                pos += 1
                return Foundation.pow(left, try parsePow())
            }
            return left
        }
        mutating func parseUnary() throws -> Double {
            if case .op(let c)? = peek(), c == "-" { pos += 1; return try -parseUnary() }
            if case .op(let c)? = peek(), c == "+" { pos += 1; return try parseUnary() }
            return try parsePrimary()
        }
        mutating func parsePrimary() throws -> Double {
            switch next() {
            case .number(let n): return n
            case .op("(")?:
                let v = try parseExpr()
                try expect(")")
                return v
            case .ident(let name)?:
                if case .op("(")? = peek() {
                    pos += 1
                    var args: [Double] = []
                    if case .op(")")? = peek() {} else {
                        args.append(try parseExpr())
                        while case .op(",")? = peek() { pos += 1; args.append(try parseExpr()) }
                    }
                    try expect(")")
                    guard let fn = Expression.funcs[name] else { throw ExpressionError.unknownFunction(name) }
                    return fn(args)
                }
                guard let v = scope[name] else { throw ExpressionError.unknownVariable(name) }
                return v
            default:
                throw ExpressionError.syntax("unexpected token in: \(source)")
            }
        }
    }
}

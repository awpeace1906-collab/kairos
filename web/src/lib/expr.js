// Tiny safe arithmetic evaluator for calculator `formula` expressions.
// Grammar: numbers, variable names, + - * / ^, unary -, parentheses, and a
// whitelisted set of single/multi-arg functions. No eval, no property access.

const FUNCS = {
  sqrt: Math.sqrt,
  cbrt: Math.cbrt,
  abs: Math.abs,
  ln: Math.log,
  log10: Math.log10,
  exp: Math.exp,
  min: Math.min,
  max: Math.max,
  round: Math.round,
  floor: Math.floor,
  ceil: Math.ceil,
};

export function evaluate(expression, scope = {}) {
  const tokens = tokenize(expression);
  let pos = 0;

  const peek = () => tokens[pos];
  const next = () => tokens[pos++];
  const expect = (t) => {
    if (peek() !== t) throw new Error(`expected "${t}" in: ${expression}`);
    return next();
  };

  function parseExpr() {
    return parseAddSub();
  }
  function parseAddSub() {
    let left = parseMulDiv();
    while (peek() === "+" || peek() === "-") {
      const op = next();
      const right = parseMulDiv();
      left = op === "+" ? left + right : left - right;
    }
    return left;
  }
  function parseMulDiv() {
    let left = parsePow();
    while (peek() === "*" || peek() === "/") {
      const op = next();
      const right = parsePow();
      left = op === "*" ? left * right : left / right;
    }
    return left;
  }
  function parsePow() {
    const left = parseUnary();
    if (peek() === "^") {
      next();
      return Math.pow(left, parsePow()); // right-associative
    }
    return left;
  }
  function parseUnary() {
    if (peek() === "-") {
      next();
      return -parseUnary();
    }
    if (peek() === "+") {
      next();
      return parseUnary();
    }
    return parsePrimary();
  }
  function parsePrimary() {
    const t = peek();
    if (t === "(") {
      next();
      const v = parseExpr();
      expect(")");
      return v;
    }
    if (typeof t === "number") {
      next();
      return t;
    }
    if (typeof t === "string" && /^[a-zA-Z_]/.test(t)) {
      next();
      if (peek() === "(") {
        next();
        const args = [];
        if (peek() !== ")") {
          args.push(parseExpr());
          while (peek() === ",") {
            next();
            args.push(parseExpr());
          }
        }
        expect(")");
        const fn = FUNCS[t];
        if (!fn) throw new Error(`unknown function "${t}"`);
        return fn(...args);
      }
      if (!(t in scope)) throw new Error(`unknown variable "${t}"`);
      const v = Number(scope[t]);
      if (Number.isNaN(v)) throw new Error(`variable "${t}" is not a number`);
      return v;
    }
    throw new Error(`unexpected token "${t}" in: ${expression}`);
  }

  const result = parseExpr();
  if (pos !== tokens.length) throw new Error(`trailing tokens in: ${expression}`);
  return result;
}

function tokenize(src) {
  const out = [];
  let i = 0;
  while (i < src.length) {
    const c = src[i];
    if (c === " " || c === "\t" || c === "\n") {
      i++;
      continue;
    }
    if ("+-*/^(),".includes(c)) {
      out.push(c);
      i++;
      continue;
    }
    if (/[0-9.]/.test(c)) {
      let j = i + 1;
      while (j < src.length && /[0-9.eE]/.test(src[j])) {
        if ((src[j] === "e" || src[j] === "E") && (src[j + 1] === "+" || src[j + 1] === "-")) j++;
        j++;
      }
      out.push(Number(src.slice(i, j)));
      i = j;
      continue;
    }
    if (/[a-zA-Z_]/.test(c)) {
      let j = i + 1;
      while (j < src.length && /[a-zA-Z0-9_]/.test(src[j])) j++;
      out.push(src.slice(i, j));
      i = j;
      continue;
    }
    throw new Error(`bad character "${c}" in: ${src}`);
  }
  return out;
}

local dumb = require("utils.dumbparse")

local scr = io.stdin:read("a")

local ast = dumb.parse(scr)
--dumb.optimize(ast)
--dumb.updateReferences(ast)
dumb.minify(ast)

-- analyize code for minification

print(dumb.toLua(ast, false))
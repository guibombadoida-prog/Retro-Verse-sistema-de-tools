
--- Esta Tool não tem cutscene. As três portas de câmera existem como no-op
--- para o `despachar` não precisar de um caminho diferente: um `if` a menos no
--- caminho quente, e nenhuma chance de chamar função nil.
function beatCena(_nome) end
function comecarCena(_qual) end
function acabarCena() end

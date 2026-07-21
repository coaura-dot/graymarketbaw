require_relative "../config/environment"

puts "Limpando banco..."
ItemVenda.delete_all
Venda.delete_all
Produto.delete_all
Usuario.delete_all

puts "Criando usuários..."
vendedor = Usuario.create!(
  nome: "Loja Oficial BAWMC",
  email: "loja@bawmc.net",
  cpf: "00000000000",
  telefone: "(62) 90000-0000",
  senha: "123456"
)

comprador = Usuario.create!(
  nome: "Steve_BR",
  email: "steve@bawmc.net",
  cpf: "11111111111",
  telefone: "(62) 91111-1111",
  senha: "123456"
)

puts "Criando produtos..."
produtos = [
  { nome: "Espada de Netherite Full Encantada", categoria: "Netherite",
    descricao: "Sharpness V, Fire Aspect II, Looting III, Unbreaking III, Mending.",
    preco: 45.00, estoque: 8 },
  { nome: "Peitoral de Netherite Full Encantado", categoria: "Netherite",
    descricao: "Protection IV, Unbreaking III, Mending, Thorns III.",
    preco: 60.00, estoque: 6 },
  { nome: "Calça de Netherite Full Encantada", categoria: "Netherite",
    descricao: "Protection IV, Unbreaking III, Mending.",
    preco: 55.00, estoque: 6 },
  { nome: "Botas de Netherite Full Encantadas", categoria: "Netherite",
    descricao: "Protection IV, Unbreaking III, Mending, Feather Falling IV, Soul Speed III.",
    preco: 50.00, estoque: 6 },
  { nome: "Capacete de Netherite Full Encantado", categoria: "Netherite",
    descricao: "Protection IV, Unbreaking III, Mending, Respiration III, Aqua Affinity.",
    preco: 50.00, estoque: 6 },
  { nome: "Machado de Netherite Full Encantado", categoria: "Netherite",
    descricao: "Sharpness V, Unbreaking III, Mending, Efficiency V.",
    preco: 42.00, estoque: 7 },
  { nome: "Maça (Mace) Encantada", categoria: "Maça",
    descricao: "Density V, Wind Burst II, Unbreaking III, Mending. Ideal para combos com Wind Charge.",
    preco: 75.00, estoque: 4 },
  { nome: "Tridente Encantado", categoria: "Tridente",
    descricao: "Loyalty III, Impaling V, Unbreaking III, Mending.",
    preco: 65.00, estoque: 3 },
  { nome: "Tridente Riptide Encantado", categoria: "Tridente",
    descricao: "Riptide III, Channeling, Unbreaking III, Mending. Ótimo para dias de chuva.",
    preco: 80.00, estoque: 2 },
  { nome: "Bloco de Diamante", categoria: "Diamante",
    descricao: "Bloco maciço de diamante puro, 9 diamantes compactados.",
    preco: 20.00, estoque: 40 },
  { nome: "Diamante (Stack de 64)", categoria: "Diamante",
    descricao: "Um stack completo de diamantes brutos para suas construções e encantamentos.",
    preco: 15.00, estoque: 30 },
  { nome: "Bloco de Obsidiana", categoria: "Blocos",
    descricao: "Bloco resistente a explosões, ideal para portais e bases PVP.",
    preco: 3.00, estoque: 120 },
  { nome: "Bloco de Netherite", categoria: "Blocos",
    descricao: "O bloco mais resistente do jogo, feito de 9 lingotes de netherite.",
    preco: 90.00, estoque: 5 },
  { nome: "Kit PVP Completo", categoria: "Kits",
    descricao: "Shulker Box contendo: armadura de netherite full encantada, espada, machado, arco encantado, cristais do End e blocos de obsidiana.",
    preco: 150.00, estoque: 3 },
  { nome: "Kit Iniciante do Servidor", categoria: "Kits",
    descricao: "Shulker Box com ferramentas de diamante encantadas, alguns blocos de obsidiana e comida.",
    preco: 40.00, estoque: 10 },
  { nome: "Cristal do End (End Crystal) - Stack", categoria: "Kits",
    descricao: "Stack de cristais do End para uso em Ender Dragon fights ou crystal PVP.",
    preco: 25.00, estoque: 15 }
]

produtos.each { |attrs| vendedor.produtos.create!(attrs) }

puts "Criando uma venda de exemplo..."
espada = vendedor.produtos.find_by(nome: "Espada de Netherite Full Encantada")
venda = Venda.finalizar_compra!(
  comprador: comprador,
  carrinho: { espada.id.to_s => 1 },
  endereco_entrega: "Spawn, x:0 y:70 z:0"
)
venda.update!(status: "paga")

puts "Seed concluído!"
puts "Login vendedor: loja@bawmc.net / 123456"
puts "Login comprador: steve@bawmc.net / 123456"

require "securerandom"

# Helpers simples para criar registros nos testes, sem depender de
# FactoryBot (que não está no Gemfile). Cada chamada gera dados únicos
# (e-mail aleatório) para não colidir com a validação de unicidade.
module Factories
  def cria_usuario(nome: "Steve", email: nil, cpf: "111.111.111-11", telefone: "62999990000", senha: "123456")
    Usuario.create!(
      nome: nome,
      email: email || "usuario_#{SecureRandom.hex(4)}@bawmc.net",
      cpf: cpf,
      telefone: telefone,
      senha: senha
    )
  end

  def cria_produto(vendedor:, nome: "Espada de Netherite Encantada", preco: 49.90, estoque: 10, categoria: "Netherite")
    Produto.create!(
      vendedor: vendedor,
      nome: nome,
      descricao: "Item temático do BAWMC.net",
      preco: preco,
      estoque: estoque,
      categoria: categoria
    )
  end

  def cria_venda(comprador:, vendedor:, status: "pendente")
    Venda.create!(
      comprador: comprador,
      vendedor: vendedor,
      status: status
    )
  end

  def cria_item_venda(venda:, produto:, quantidade: 1, preco_unitario: nil)
    ItemVenda.create!(
      venda: venda,
      produto: produto,
      quantidade: quantidade,
      preco_unitario: preco_unitario || produto.preco
    )
  end
end

RSpec.configure do |config|
  config.include Factories
end

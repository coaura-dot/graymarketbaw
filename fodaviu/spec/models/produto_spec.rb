require "spec_helper"

RSpec.describe Produto do
  describe "validações" do
    it "é válido com atributos completos" do
      vendedor = cria_usuario
      produto = Produto.new(vendedor: vendedor, nome: "Machado de Netherite", preco: 30, estoque: 5)
      expect(produto).to be_valid
    end

    it "é inválido sem nome" do
      vendedor = cria_usuario
      produto = Produto.new(vendedor: vendedor, preco: 30, estoque: 5)
      expect(produto).not_to be_valid
      expect(produto.errors[:nome]).not_to be_empty
    end

    it "é inválido com preço zero ou negativo" do
      vendedor = cria_usuario
      produto = Produto.new(vendedor: vendedor, nome: "Item", preco: 0, estoque: 5)
      expect(produto).not_to be_valid
      expect(produto.errors[:preco]).not_to be_empty

      produto.preco = -10
      expect(produto).not_to be_valid
    end

    it "é inválido com estoque negativo" do
      vendedor = cria_usuario
      produto = Produto.new(vendedor: vendedor, nome: "Item", preco: 10, estoque: -1)
      expect(produto).not_to be_valid
      expect(produto.errors[:estoque]).not_to be_empty
    end

    it "é válido com estoque igual a zero" do
      vendedor = cria_usuario
      produto = Produto.new(vendedor: vendedor, nome: "Item", preco: 10, estoque: 0)
      expect(produto).to be_valid
    end
  end

  describe "associações" do
    it "pertence a um vendedor" do
      vendedor = cria_usuario
      produto = cria_produto(vendedor: vendedor)
      expect(produto.vendedor).to eq(vendedor)
    end

    it "tem muitos item_vendas e vendas através deles" do
      vendedor = cria_usuario
      comprador = cria_usuario
      produto = cria_produto(vendedor: vendedor)
      venda = cria_venda(comprador: comprador, vendedor: vendedor)
      cria_item_venda(venda: venda, produto: produto)

      expect(produto.vendas).to include(venda)
    end
  end

  describe "#disponivel?" do
    it "retorna true quando o estoque é maior que zero" do
      produto = cria_produto(vendedor: cria_usuario, estoque: 3)
      expect(produto.disponivel?).to be true
    end

    it "retorna false quando o estoque é zero" do
      produto = cria_produto(vendedor: cria_usuario, estoque: 0)
      expect(produto.disponivel?).to be false
    end
  end

  describe ".busca" do
    it "encontra produtos pelo nome, ignorando maiúsculas/minúsculas" do
      vendedor = cria_usuario
      cria_produto(vendedor: vendedor, nome: "Espada de Netherite")
      cria_produto(vendedor: vendedor, nome: "Tridente Encantado", categoria: "Tridente")

      resultado = Produto.busca("netherite")
      expect(resultado.map(&:nome)).to include("Espada de Netherite")
      expect(resultado.map(&:nome)).not_to include("Tridente Encantado")
    end

    it "encontra produtos pela categoria" do
      vendedor = cria_usuario
      cria_produto(vendedor: vendedor, nome: "Kit Completo", categoria: "Kits")

      resultado = Produto.busca("kits")
      expect(resultado.map(&:nome)).to include("Kit Completo")
    end

    it "retorna todos os produtos quando o termo está em branco" do
      vendedor = cria_usuario
      cria_produto(vendedor: vendedor)
      expect(Produto.busca(nil).count).to eq(Produto.count)
      expect(Produto.busca("").count).to eq(Produto.count)
    end
  end
end
